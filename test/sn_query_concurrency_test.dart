import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_mes_tool/modules/logic.dart';

http.Response reply(Object data) =>
    http.Response(jsonEncode({'code': 200, 'data': data}), 200);

bool master(http.Request r) => r.url.path.contains('getSnMasterProcess');
bool testRecord(http.Request r) => r.url.path.contains('pageTestRecordLists');

AppLogic isolated({int concurrency = 6}) => AppLogic(
  initialize: false,
  queryConcurrency: concurrency,
  saveConfig: (_) async {},
);

void main() {
  test(
    're-submitted SN becomes newest and selected without duplicate or refetch',
    () async {
      Map<String, dynamic>? saved;
      var requests = 0;
      await http.runWithClient(
        () async {
          final app = AppLogic(
            initialize: false,
            saveConfig: (config) async {
              saved = config;
            },
          );
          addTearDown(app.dispose);
          await app.addSns('OLD MIDDLE NEW', allowTestRecordFallback: false);
          await app.queriesIdle;
          final cached = app.results['OLD'];
          final previousRequests = requests;
          await app.addSns(' old old ', allowTestRecordFallback: false);
          await app.queriesIdle;
          expect(app.snList, ['MIDDLE', 'NEW', 'OLD']);
          expect(app.selectedSn, 'OLD');
          expect(saved!['sns'], ['MIDDLE', 'NEW', 'OLD']);
          expect(app.results['OLD'], same(cached));
          expect(requests, previousRequests);
          app.selectSn('MIDDLE');
          expect(app.snList, ['MIDDLE', 'NEW', 'OLD']);
          await app.addSns('NEW FRESH MIDDLE', allowTestRecordFallback: false);
          await app.queriesIdle;
          expect(app.snList, ['OLD', 'NEW', 'FRESH', 'MIDDLE']);
          expect(app.selectedSn, 'MIDDLE');
        },
        () => MockClient((r) async {
          requests++;
          if (master(r)) return reply({'sn': jsonDecode(r.body)['sn']});
          return reply([]);
        }),
      );
    },
  );

  for (final savedSns in <List<String>>[
    [],
    ['ONLY'],
    ['OLD', 'MIDDLE', 'NEW'],
  ]) {
    test('startup selects newest saved SN from $savedSns', () async {
      await http.runWithClient(
        () async {
          final loaded = Completer<void>();
          final app = AppLogic(
            loadConfig: () async => {
              'sns': savedSns,
              'token': 'fake-test-token',
            },
            saveConfig: (_) async {},
          );
          addTearDown(app.dispose);
          app.addListener(() {
            if (!loaded.isCompleted) loaded.complete();
          });
          await loaded.future;
          expect(app.selectedSn, savedSns.isEmpty ? '' : savedSns.last);
          expect(app.snList, savedSns);
          await app.queriesIdle;
          expect(app.selectedSn, savedSns.isEmpty ? '' : savedSns.last);
        },
        () => MockClient((r) async {
          if (master(r)) return reply({'sn': jsonDecode(r.body)['sn']});
          return reply([]);
        }),
      );
    });
  }

  test(
    'batch and refresh load all SN views newest-first without reversing storage',
    () async {
      final requests = <String>[];
      await http.runWithClient(
        () async {
          final app = isolated(concurrency: 1);
          addTearDown(app.dispose);
          await app.addSns('OLD MIDDLE NEW', allowTestRecordFallback: false);
          await app.queriesIdle;
          expect(app.snList, ['OLD', 'MIDDLE', 'NEW']);
          expect(requests, [
            'NEW',
            'NEW',
            'NEW',
            'MIDDLE',
            'MIDDLE',
            'MIDDLE',
            'OLD',
            'OLD',
            'OLD',
          ]);
          requests.clear();
          await app.refreshAll();
          await app.queriesIdle;
          expect(requests, [
            'NEW',
            'NEW',
            'NEW',
            'MIDDLE',
            'MIDDLE',
            'MIDDLE',
            'OLD',
            'OLD',
            'OLD',
          ]);
          expect(app.snList, ['OLD', 'MIDDLE', 'NEW']);
        },
        () => MockClient((r) async {
          final sn = r.method == 'GET'
              ? r.url.queryParameters['sn']!
              : jsonDecode(r.body)['sn'] as String;
          if (master(r)) return reply({'sn': sn});
          requests.add(sn);
          return reply([]);
        }),
      );
    },
  );

  test('new SN added during loading overtakes older pending SNs', () async {
    final firstStarted = Completer<void>();
    final release = Completer<void>();
    final resolved = <String>[];
    await http.runWithClient(
      () async {
        final app = isolated(concurrency: 1);
        addTearDown(app.dispose);
        await app.addSns('OLD MIDDLE', allowTestRecordFallback: false);
        await firstStarted.future;
        await app.addSns('NEW', allowTestRecordFallback: false);
        expect(resolved, ['MIDDLE']);
        release.complete();
        await app.queriesIdle;
        expect(resolved, ['MIDDLE', 'NEW', 'OLD']);
        expect(app.snList, ['OLD', 'MIDDLE', 'NEW']);
      },
      () => MockClient((r) async {
        if (master(r)) {
          final sn = jsonDecode(r.body)['sn'] as String;
          resolved.add(sn);
          if (!firstStarted.isCompleted) {
            firstStarted.complete();
            await release.future;
          }
          return reply({'sn': sn});
        }
        return reply([]);
      }),
    );
  });

  test('credential change discards late errors and refetches', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var first = true;
    await http.runWithClient(
      () async {
        final app = isolated();
        await app.addSns('A');
        await started.future;
        await app.updateCredentials(
          token: 'fake-test-token',
          uuid: 'fake',
          operationId: 'fake',
          cookie: '',
        );
        release.complete();
        await app.queriesIdle;
        expect(app.errors.containsKey('A'), isFalse);
        expect(app.results['A']!.single.sn, 'fresh');
        app.dispose();
      },
      () => MockClient((r) async {
        if (master(r)) return reply({'sn': 'A'});
        if (testRecord(r)) {
          if (first) {
            first = false;
            started.complete();
            await release.future;
            return http.Response('old failure', 500);
          }
          return reply([
            {'sn': 'fresh'},
          ]);
        }
        return reply([]);
      }),
    );
  });

  test(
    'background trace preserves selection and ignores removed CSN',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var hold = false;
      await http.runWithClient(
        () async {
          final app = isolated();
          await app.addTraceCsns('C1 C2');
          hold = true;
          final batch = app.refetchAllTraceSearches();
          await started.future;
          app.selectTraceCsn('C1');
          app.removeTraceCsn('C2');
          release.complete();
          await batch;
          expect(app.selectedTraceCsn, 'C1');
          expect(app.traceResults.containsKey('C2'), isFalse);
          expect(app.traceLoadingStatus.containsKey('C2'), isFalse);
          app.dispose();
        },
        () => MockClient((r) async {
          if (hold) {
            if (!started.isCompleted) started.complete();
            await release.future;
          }
          return reply([]);
        }),
      );
    },
  );

  test(
    'new SN joins active batch, requests bounded and master shared',
    () async {
      await http.runWithClient(() async {
        final app = isolated();
        await app.addSns('A B C');
        await app.addSns('D E F G');
        await app.queriesIdle;
        expect(app.results.length, 7);
        expect(app.processResults.length, 7);
        expect(app.wipResults.length, 7);
        app.dispose();
      }, () => _CountingClient());
    },
  );

  for (final action in ['refresh', 'remove-readd', 'clear', 'dispose']) {
    test('late test result cannot overwrite after $action', () async {
      final started = Completer<void>();
      final release = Completer<void>();
      var first = true;
      await http.runWithClient(
        () async {
          final app = isolated();
          await app.addSns('A');
          await started.future;
          Future<void>? refresh;
          if (action == 'refresh') refresh = app.refreshSn('A');
          if (action == 'remove-readd') {
            app.removeSn('A');
            await app.addSns('A');
          }
          if (action == 'clear') app.clearAllSns();
          if (action == 'dispose') app.dispose();
          if (refresh != null) await refresh;
          if (action == 'refresh') {
            expect(app.results['A']!.single.sn, 'new');
          }
          release.complete();
          await app.queriesIdle;
          if (action == 'refresh' || action == 'remove-readd') {
            expect(app.results['A']!.single.sn, 'new');
            expect(app.loadingStatus['A'], isFalse);
          } else {
            expect(app.results.containsKey('A'), isFalse);
          }
          if (action != 'dispose') app.dispose();
        },
        () => MockClient((r) async {
          if (master(r)) return reply({'sn': 'A'});
          if (testRecord(r)) {
            if (first) {
              first = false;
              started.complete();
              await release.future;
              return reply([
                {'sn': 'old'},
              ]);
            }
            return reply([
              {'sn': 'new'},
            ]);
          }
          return reply([]);
        }),
      );
    });
  }

  test('late master cannot restore deleted SN metadata', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    var resolves = 0;
    await http.runWithClient(
      () async {
        final app = isolated();
        await app.addSns('A');
        await started.future;
        app.removeSn('A');
        release.complete();
        await app.queriesIdle;
        expect(resolves, 1);
        expect(app.resolvedSnFor('A'), isNull);
        expect(app.snMasterInfo, isEmpty);
        expect(app.results, isEmpty);
        app.dispose();
      },
      () => MockClient((r) async {
        if (master(r)) {
          resolves++;
          if (!started.isCompleted) started.complete();
          await release.future;
          return reply({'sn': 'canonical'});
        }
        fail('No detail request should start after removal');
      }),
    );
  });
}

class _CountingClient extends MockClient {
  _CountingClient() : super(_handle);
  static int active = 0;
  static final Set<String> resolved = {};
  static Future<http.Response> _handle(http.Request request) async {
    active++;
    expect(active, lessThanOrEqualTo(6));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    active--;
    if (master(request)) {
      final sn = jsonDecode(request.body)['sn'] as String;
      expect(resolved.add(sn), isTrue);
      return reply({'sn': sn});
    }
    return reply([]);
  }
}
