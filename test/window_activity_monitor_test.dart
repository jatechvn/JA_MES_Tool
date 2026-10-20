import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
import 'package:ja_mes_tool/modules/services/window_activity_monitor.dart';

void main() {
  late AppPowerManager power;
  setUp(() => power = AppPowerManager.create());
  tearDown(() => power.dispose());

  test('unlock while MES is not foreground never grants focus', () async {
    final monitor = WindowActivityMonitor(
      power: power,
      readState: () async => (visible: true, minimized: false, focused: false),
    );
    addTearDown(monitor.dispose);
    monitor.onLifecycleStateChanged(AppLifecycleState.inactive);
    monitor.onLifecycleStateChanged(AppLifecycleState.resumed);
    expect(power.shouldAnimateIndicators, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(power.shouldAnimateBackground, isFalse);
    expect(power.shouldAnimateMarquee, isFalse);
    expect(power.isWindowVisible, isTrue);
  });

  for (final state in [
    (visible: false, minimized: false, focused: true),
    (visible: true, minimized: true, focused: true),
  ]) {
    test('spurious focus/restore cannot activate $state', () async {
      final monitor = WindowActivityMonitor(
        power: power,
        readState: () async => state,
      );
      addTearDown(monitor.dispose);
      monitor.onWindowFocus();
      expect(power.shouldAnimateIndicators, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(power.shouldAnimateIndicators, isFalse);
      monitor.onWindowRestore();
      await Future<void>.delayed(Duration.zero);
      expect(power.shouldAnimateIndicators, isFalse);
    });
  }

  test('blur invalidates an older async focused snapshot', () async {
    final reply = Completer<WindowActivitySnapshot>();
    final monitor = WindowActivityMonitor(
      power: power,
      readState: () => reply.future,
    );
    addTearDown(monitor.dispose);
    final reading = monitor.reconcile();
    monitor.onWindowBlur();
    reply.complete((visible: true, minimized: false, focused: true));
    await reading;
    expect(power.shouldAnimateIndicators, isFalse);
  });

  test('dispose invalidates pending focus reply', () async {
    power.onWindowBlur();
    final reply = Completer<WindowActivitySnapshot>();
    final monitor = WindowActivityMonitor(
      power: power,
      readState: () => reply.future,
    );
    final reading = monitor.reconcile();
    monitor.dispose();
    reply.complete((visible: true, minimized: false, focused: true));
    await reading;
    expect(power.shouldAnimateIndicators, isFalse);
  });

  test(
    'native query failure stays muted and later verification recovers',
    () async {
      var fail = true;
      final monitor = WindowActivityMonitor(
        power: power,
        readState: () async {
          if (fail) throw StateError('native unavailable');
          return (visible: true, minimized: false, focused: true);
        },
      );
      addTearDown(monitor.dispose);
      await monitor.reconcile();
      expect(power.shouldAnimateIndicators, isFalse);
      fail = false;
      await monitor.reconcile();
      expect(power.shouldAnimateIndicators, isTrue);
    },
  );

  testWidgets('polling recovers missed blur/focus and cancels on disposal', (
    tester,
  ) async {
    var focused = true;
    var reads = 0;
    final monitor = WindowActivityMonitor(
      power: power,
      pollInterval: const Duration(milliseconds: 100),
      readState: () async {
        reads++;
        return (visible: true, minimized: false, focused: focused);
      },
    );
    monitor.start();
    await tester.pump();
    expect(power.shouldAnimateIndicators, isTrue);
    focused = false;
    await tester.pump(const Duration(milliseconds: 100));
    expect(power.shouldAnimateIndicators, isFalse);
    focused = true;
    await tester.pump(const Duration(milliseconds: 100));
    expect(power.shouldAnimateIndicators, isTrue);
    monitor.dispose();
    final stoppedAt = reads;
    await tester.pump(const Duration(seconds: 1));
    expect(reads, stoppedAt);
    power.onWindowBlur();
  });

  testWidgets('a stuck native read times out and the monitor can recover', (
    tester,
  ) async {
    var stuck = true;
    final pending = Completer<WindowActivitySnapshot>();
    final monitor = WindowActivityMonitor(
      power: power,
      readTimeout: const Duration(milliseconds: 20),
      pollInterval: const Duration(milliseconds: 100),
      readState: () => stuck
          ? pending.future
          : Future.value((visible: true, minimized: false, focused: true)),
    );
    monitor.start();
    await tester.pump(const Duration(milliseconds: 30));
    expect(power.shouldAnimateIndicators, isFalse);
    stuck = false;
    await tester.pump(const Duration(milliseconds: 100));
    expect(power.shouldAnimateIndicators, isTrue);
    pending.complete((visible: true, minimized: false, focused: false));
    await tester.pump();
    expect(
      power.shouldAnimateIndicators,
      isTrue,
      reason: 'Timed-out reply cannot overwrite recovery',
    );
    monitor.dispose();
    power.onWindowBlur();
  });

  testWidgets(
    'unchanged native polls do not postpone idle or notify animation listeners',
    (tester) async {
      power.setIdleTimeout(const Duration(milliseconds: 300));
      final monitor = WindowActivityMonitor(
        power: power,
        pollInterval: const Duration(milliseconds: 100),
        readState: () async => (visible: true, minimized: false, focused: true),
      );
      monitor.start();
      await tester.pump();
      var notifications = 0;
      power.indicatorsAnimationNotifier.addListener(() => notifications++);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(power.isUserIdle, isTrue);
      expect(power.shouldAnimateBackground, isFalse);
      expect(power.shouldAnimateIndicators, isTrue);
      expect(notifications, 0);
      monitor.dispose();
    },
  );
}
