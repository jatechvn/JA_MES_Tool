import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/query_queue.dart';

void main() {
  test('bounds jobs, deduplicates and skips invalid queued jobs', () async {
    final queue = QueryQueue(concurrency: 2);
    final gate = Completer<void>();
    var calls = 0;
    var valid = true;
    Future<void> work() async {
      calls++;
      await gate.future;
    }

    final first = queue.run('a', work, isCurrent: () => true);
    expect(
      identical(first, queue.run('a', work, isCurrent: () => true)),
      isTrue,
    );
    final second = queue.run('b', work, isCurrent: () => true);
    final stale = queue.run('c', work, isCurrent: () => valid);
    expect(calls, 2);
    valid = false;
    gate.complete();
    await Future.wait([first, second, stale]);
    await queue.idle;
    expect(calls, 2);
  });

  test('error releases slot and newly added jobs run', () async {
    final queue = QueryQueue(concurrency: 1);
    final failed = queue.run(
      'bad',
      () async => throw StateError('fake'),
      isCurrent: () => true,
    );
    var ran = false;
    final next = queue.run('good', () async {
      ran = true;
    }, isCurrent: () => true);
    await expectLater(failed, throwsStateError);
    await next;
    expect(ran, isTrue);
  });
}
