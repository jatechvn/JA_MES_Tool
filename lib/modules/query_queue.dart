import 'dart:async';
import 'dart:collection';

/// Bounded asynchronous jobs. Stale queued jobs settle without making requests.
class QueryQueue {
  QueryQueue({this.concurrency = 6}) {
    if (concurrency < 1) throw ArgumentError.value(concurrency);
  }

  final int concurrency;
  final Queue<_Job> _pending = Queue<_Job>();
  final Map<Object, Future<void>> _jobs = {};
  int _active = 0;

  Future<void> get idle async {
    while (_jobs.isNotEmpty) {
      await Future.wait(List<Future<void>>.of(_jobs.values));
    }
  }

  Future<void> run(
    Object key,
    Future<void> Function() action, {
    required bool Function() isCurrent,
  }) {
    final existing = _jobs[key];
    if (existing != null) return existing;
    final done = Completer<void>();
    _jobs[key] = done.future;
    _pending.add(_Job(key, action, isCurrent, done));
    _drain();
    return done.future;
  }

  void _drain() {
    while (_active < concurrency && _pending.isNotEmpty) {
      final job = _pending.removeFirst();
      if (!job.isCurrent()) {
        _jobs.remove(job.key);
        job.done.complete();
        continue;
      }
      _active++;
      _execute(job);
    }
  }

  Future<void> _execute(_Job job) async {
    try {
      await job.action();
      job.done.complete();
    } catch (error, stack) {
      job.done.completeError(error, stack);
    } finally {
      _jobs.remove(job.key);
      _active--;
      _drain();
    }
  }
}

class _Job {
  _Job(this.key, this.action, this.isCurrent, this.done);
  final Object key;
  final Future<void> Function() action;
  final bool Function() isCurrent;
  final Completer<void> done;
}
