import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';
import 'package:ja_mes_tool/modules/ui/main_window.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

http.Response response(Object? data, {Object code = 200}) =>
    http.Response(jsonEncode({'code': code, 'data': data}), 200);

Future<TestRecordPage> fetch({
  String wo = '000400003821',
  int page = 1,
  int size = 100,
}) => ApiClient.fetchWorkOrderPage(
  woNo: wo,
  pageIndex: page,
  pageSize: size,
  token: 'Bearer fake-token',
  lang: 'en',
  operationId: 'fake-op',
  uuid: 'fake-uuid',
  cookie: 'fake-cookie=1',
);

void main() {
  test(
    'WO contract uses encoded woNo, empty SN, configured headers and requested page',
    () async {
      await http.runWithClient(
        () async {
          final page = await fetch(wo: ' 000400003821&A ', page: 2);
          expect(page.pageIndex, 2);
          expect(page.totalCount, 201);
          expect(page.hasNext, isTrue);
          expect(page.records.single.sn, 'SN-1');
        },
        () => MockClient((r) async {
          expect(r.method, 'GET');
          expect(r.url.path, endsWith('/equipmentRecord/pageTestRecordLists'));
          expect(r.url.queryParameters['woNo'], '000400003821&A');
          expect(r.url.queryParameters['sn'], '');
          expect(r.url.queryParameters['pageIndex'], '2');
          expect(r.url.queryParameters['pageSize'], '100');
          expect(r.url.queryParameters['orgCode'], 'CABG_VN');
          expect(r.url.queryParameters['testEndDate'], '');
          expect(r.headers['Authorization'], 'bearer fake-token');
          expect(r.headers['Cookie'], 'fake-cookie=1');
          expect(r.headers['factoryid'], '13');
          return response({
            'records': [
              {'sn': 'SN-1'},
            ],
            'totalCount': '201',
          });
        }),
      );
    },
  );

  for (final listKey in ['list', 'records', 'rows']) {
    test('parses $listKey and total metadata', () async {
      await http.runWithClient(
        () async {
          final page = await fetch();
          expect(page.records.single.internalSn, 'INTERNAL');
          expect(page.hasNext, isFalse);
        },
        () => MockClient(
          (_) async => response({
            listKey: [
              {'internalSn': 'INTERNAL'},
            ],
            'total': 1,
          }),
        ),
      );
    });
  }

  test(
    'without total, a full page can continue and an empty page stops',
    () async {
      await http.runWithClient(
        () async {
          expect((await fetch(size: 2)).hasNext, isTrue);
          expect((await fetch(size: 2, page: 2)).hasNext, isFalse);
        },
        () => MockClient(
          (r) async => response(
            r.url.queryParameters['pageIndex'] == '1'
                ? [
                    {'sn': 'A'},
                    {'sn': 'B'},
                  ]
                : [],
          ),
        ),
      );
    },
  );

  test('invalid input never dispatches HTTP', () async {
    await http.runWithClient(() async {
      expect(() => fetch(wo: ' '), throwsArgumentError);
      expect(() => fetch(page: 0), throwsArgumentError);
      expect(() => fetch(size: 101), throwsArgumentError);
    }, () => MockClient((_) async => throw StateError('Must not request')));
  });

  for (final kind in ['HTTP401', 'API401', 'malformed']) {
    test('$kind is not interpreted as an empty successful page', () async {
      await http.runWithClient(
        () async {
          await expectLater(fetch(), throwsA(isA<Exception>()));
        },
        () => MockClient(
          (_) async => switch (kind) {
            'HTTP401' => http.Response('', 401),
            'API401' => response(null, code: 401),
            _ => http.Response('not json', 200),
          },
        ),
      );
    });
  }

  test(
    'WO query bypasses master lookup and preserves SN caches/selection',
    () async {
      final logic = AppLogic(initialize: false, saveConfig: (_) async {});
      addTearDown(logic.dispose);
      logic.snList.add('SN-EXISTING');
      final cached = [
        TestRecord.fromJson({'sn': 'SN-EXISTING'}),
      ];
      logic.results['SN-EXISTING'] = cached;
      logic.processResults['SN-EXISTING'] = [];
      logic.wipResults['SN-EXISTING'] = [];
      logic.selectSn('SN-EXISTING');
      await http.runWithClient(
        () async {
          await logic.fetchWorkOrderPage('000400003821');
          expect(logic.snList, ['SN-EXISTING']);
          expect(logic.selectedSn, 'SN-EXISTING');
          expect(logic.results['SN-EXISTING'], same(cached));
          expect(logic.snMasterInfo, isEmpty);
        },
        () => MockClient((r) async {
          expect(r.url.path, endsWith('/pageTestRecordLists'));
          return response([]);
        }),
      );
    },
  );

  test('disposed logic discards pending WO response', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final logic = AppLogic(initialize: false, saveConfig: (_) async {});
    await http.runWithClient(
      () async {
        final query = logic.fetchWorkOrderPage('000400003821');
        final assertion = expectLater(query, throwsStateError);
        await started.future;
        logic.dispose();
        pending.complete(
          response([
            {'sn': 'LATE'},
          ]),
        );
        await assertion;
      },
      () => MockClient((_) {
        started.complete();
        return pending.future;
      }),
    );
  });

  test('credential replacement rejects an in-flight WO response', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final logic = AppLogic(initialize: false, saveConfig: (_) async {});
    addTearDown(logic.dispose);
    await http.runWithClient(
      () async {
        final query = logic.fetchWorkOrderPage('000400003821');
        final assertion = expectLater(query, throwsStateError);
        await started.future;
        await logic.updateSettings(
          token: 'new-fake-token',
          lang: 'en',
          operationId: 'op',
          uuid: 'uuid',
          cookie: '',
        );
        pending.complete(
          response([
            {'sn': 'OLD-CREDENTIALS'},
          ]),
        );
        await assertion;
      },
      () => MockClient((r) {
        if (r.url.queryParameters['woNo'] == '000400003821') {
          started.complete();
          return pending.future;
        }
        return Future.value(response([]));
      }),
    );
  });

  test(
    'addWorkOrders fetches pages, deduplicates unit SNs and populates snList',
    () async {
      final logic = AppLogic(initialize: false, saveConfig: (_) async {});
      addTearDown(logic.dispose);
      final woPagesRequested = <String>[];
      await http.runWithClient(
        () async {
          await logic.addWorkOrders('000400003821');
          await logic.queriesIdle;
          expect(woPagesRequested, ['1', '2']);
          expect(logic.snList, ['INTERNAL-1', 'INTERNAL-2']);
          expect(logic.selectedSn, 'INTERNAL-2');
          expect(logic.results['INTERNAL-1'], isNotEmpty);
          expect(logic.results['INTERNAL-2'], isNotEmpty);
        },
        () => MockClient((r) async {
          if (r.url.path.endsWith('/pageTestRecordLists') &&
              (r.url.queryParameters['woNo'] ?? '').isNotEmpty) {
            final page = r.url.queryParameters['pageIndex']!;
            woPagesRequested.add(page);
            if (page == '1') {
              return response({
                'list': [
                  {
                    'sn': 'SN-1',
                    'internalSn': 'INTERNAL-1',
                    'customerSn': 'CUSTOMER-1',
                    'result': 'PASS',
                    'woNo': '000400003821',
                  },
                  // Duplicate record for same unit on another station
                  {
                    'sn': 'SN-1',
                    'internalSn': 'INTERNAL-1',
                    'customerSn': 'CUSTOMER-1',
                    'result': 'PASS',
                    'woNo': '000400003821',
                  },
                ],
                'total': 101,
              });
            }
            return response({
              'list': [
                {
                  'sn': 'SN-2',
                  'internalSn': 'INTERNAL-2',
                  'customerSn': 'CUSTOMER-2',
                  'result': 'PASS',
                  'woNo': '000400003821',
                },
              ],
              'total': 101,
            });
          }
          if (r.url.path.endsWith('/pageTestRecordLists')) {
            final sn = r.url.queryParameters['sn'] ?? '';
            return response([
              {'sn': sn, 'internalSn': sn, 'result': 'PASS'},
            ]);
          }
          return response([]);
        }),
      );
    },
  );

  test(
    'addWorkOrders reports empty and error states via globalError',
    () async {
      final logic = AppLogic(initialize: false, saveConfig: (_) async {});
      addTearDown(logic.dispose);
      var calls = 0;
      await http.runWithClient(
        () async {
          await logic.addWorkOrders('000400003821');
          expect(logic.globalError, contains('000400003821'));
          expect(logic.snList, isEmpty);

          await logic.addWorkOrders('000400003821');
          expect(
            logic.globalError,
            Translations.get(
              'wo_empty',
              'en',
            ).replaceAll('{wo}', '000400003821'),
          );
          expect(logic.snList, isEmpty);
        },
        () => MockClient(
          (_) async => ++calls == 1 ? http.Response('', 401) : response([]),
        ),
      );
    },
  );

  for (final mode in ['light', 'dark']) {
    testWidgets(
      'MainWindow $mode toggles SN <-> WO input mode on Refresh All row and batch loads SNs',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final logic = AppLogic(initialize: false, saveConfig: (_) async {});
        final theme = ThemeProvider(initialMode: mode);
        logic.isConnectionValid = true;
        addTearDown(logic.dispose);
        addTearDown(theme.dispose);

        await http.runWithClient(
          () async {
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: logic),
                  ChangeNotifierProvider.value(value: theme),
                ],
                child: const MaterialApp(
                  debugShowCheckedModeBanner: false,
                  home: MainWindow(),
                ),
              ),
            );
            await tester.pump(const Duration(seconds: 1));

            // Old button must not exist; new toggle icon button is on the header row
            expect(find.byKey(const ValueKey('open_work_order')), findsNothing);
            final toggleFinder = find.byKey(const ValueKey('toggle_wo_mode'));
            expect(toggleFinder, findsOneWidget);

            // Initially in SN input mode
            final inputFinder = find.byKey(
              const ValueKey('sidebar_primary_input'),
            );
            expect(
              tester.widget<TextField>(inputFinder).decoration?.hintText,
              Translations.get('enter_sn', logic.lang),
            );

            // Tap toggle icon -> swaps input box to WO mode
            await tester.tap(toggleFinder);
            await tester.pump();
            expect(
              tester.widget<TextField>(inputFinder).decoration?.hintText,
              Translations.get('enter_wo', logic.lang),
            );

            // Enter WO and submit -> populates SNs in the queue below
            await tester.enterText(inputFinder, '000400003821');
            await tester.tap(
              find.byKey(const ValueKey('sidebar_submit_input')),
            );
            await tester.pump();
            await logic.queriesIdle;
            await tester.pump(const Duration(milliseconds: 300));

            expect(logic.snList, ['SAFVN2630836185', 'SAFVN2630836186']);
            expect(tester.takeException(), isNull);
          },
          () => MockClient((r) async {
            if (r.url.path.endsWith('/pageTestRecordLists') &&
                (r.url.queryParameters['woNo'] ?? '').isNotEmpty) {
              return response({
                'list': [
                  {
                    'sn': 'DHL2700003',
                    'internalSn': 'SAFVN2630836185',
                    'customerSn': 'VN0TD2147FVSG672D003A00',
                    'result': 'PASS',
                    'woNo': '000400003821',
                  },
                  {
                    'sn': 'DHL2700004',
                    'internalSn': 'SAFVN2630836186',
                    'customerSn': 'VN0TD2147FVSG672D004A00',
                    'result': 'PASS',
                    'woNo': '000400003821',
                  },
                ],
                'total': 2,
              });
            }
            return response([]);
          }),
        );
      },
    );
  }

  test('invalidated queued WO is skipped before HTTP dispatch', () async {
    final logic = AppLogic(
      initialize: false,
      queryConcurrency: 1,
      saveConfig: (_) async {},
    );
    addTearDown(logic.dispose);
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    var current = true;
    var calls = 0;
    await http.runWithClient(
      () async {
        final first = logic.fetchWorkOrderPage('FIRST');
        await started.future;
        final second = logic.fetchWorkOrderPage(
          'SECOND',
          isCurrent: () => current,
        );
        final assertion = expectLater(second, throwsStateError);
        current = false;
        pending.complete(response([]));
        await first;
        await assertion;
        expect(calls, 1);
      },
      () => MockClient((_) {
        calls++;
        started.complete();
        return pending.future;
      }),
    );
  });

  test('new WO UI strings and record labels are translated in EN/VI/ZH', () {
    for (final lang in ['en', 'vn', 'cn']) {
      for (final key in [
        'enter_wo',
        'switch_to_wo',
        'switch_to_sn',
        'wo_lookup',
        'wo_hint',
        'wo_search',
        'wo_prompt',
        'wo_error',
        'wo_empty',
        'wo_page',
        'wo_previous',
        'wo_next',
        'wo_reload',
        'line_station_code',
        'test_host',
      ]) {
        expect(Translations.get(key, lang), isNot(key));
      }
    }
  });
}
