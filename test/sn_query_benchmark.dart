// Synthetic benchmark: real AppLogic and API parsing, fake HTTP latency.
// Run explicitly: flutter test test/sn_query_benchmark.dart --reporter expanded
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_mes_tool/modules/logic.dart';

void main() {
  test(
    'benchmark 100 SN at concurrency 1/4/6',
    () async {
      for (final concurrency in [1, 4, 6]) {
        var requests = 0;
        var active = 0;
        var peak = 0;
        final times = <int>[];
        for (var trial = 0; trial < 3; trial++) {
          await http.runWithClient(
            () async {
              final app = AppLogic(
                initialize: false,
                queryConcurrency: concurrency,
                saveConfig: (_) async {},
              );
              final watch = Stopwatch()..start();
              await app.addSns(List.generate(100, (i) => 'SN$i').join(' '));
              await app.queriesIdle;
              watch.stop();
              expect(app.results.length, 100);
              expect(app.processResults.length, 100);
              expect(app.wipResults.length, 100);
              times.add(watch.elapsedMilliseconds);
              app.dispose();
            },
            () => MockClient((r) async {
              requests++;
              active++;
              if (active > peak) peak = active;
              await Future<void>.delayed(const Duration(milliseconds: 10));
              active--;
              final isMaster = r.url.path.contains('getSnMasterProcess');
              final data = isMaster
                  ? {'sn': jsonDecode(r.body)['sn']}
                  : <Object>[];
              return http.Response(
                jsonEncode({'code': 200, 'data': data}),
                200,
              );
            }),
          );
        }
        expect(requests, 1200);
        expect(peak, lessThanOrEqualTo(concurrency));
        times.sort();
        // ignore: avoid_print
        print(
          'SN_BENCH concurrency=$concurrency median_ms=${times[1]} '
          'runs_ms=$times peak_http=$peak requests_per_run=${requests ~/ 3}',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
