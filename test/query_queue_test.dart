import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/query_queue.dart';

void main() {
  test(
    'pending priority is newest-first without preempting active work',
    () async {
      final queue = QueryQueue(concurrency: 1);
      final release = Completer<void>();
      final started = <String>[];
      final active = queue.run('active', () async {
        started.add('active');
        await release.future;
      }, isCurrent: () => true);
      final ranks = {'old': 1, 'new': 2};
      Future<void> enqueue(String key) => queue.run(
        key,
        () async {
          started.add(key);
        },
        isCurrent: () => true,
        priority: () => ranks[key]!,
      );
      final old = enqueue('old');
      final newest = enqueue('new');
      final equallyNew = queue.run(
        'tie',
        () async {
          started.add('tie');
        },
        isCurrent: () => true,
        priority: () => 2,
      );
      expect(started, ['active']);
      release.complete();
      await Future.wait([active, old, newest, equallyNew]);
      expect(started, ['active', 'new', 'tie', 'old']);
    },
  );

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
