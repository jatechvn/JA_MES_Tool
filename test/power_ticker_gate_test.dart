import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
import 'package:ja_mes_tool/modules/services/power_binding.dart';

void main() {
  for (final initiallyActive in [true, false]) {
    testWidgets(
      'root gate mutes ordinary tickers and dialog overlays (initial=$initiallyActive)',
      (tester) async {
        final power = AppPowerManager.create();
        addTearDown(power.dispose);
        power.resetForTesting(isFocused: initiallyActive);
        var ticks = 0;
        var businessTicks = 0;
        final timer = Timer.periodic(
          const Duration(milliseconds: 50),
          (_) => businessTicks++,
        );
        addTearDown(timer.cancel);
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            builder: (_, child) => PowerTickerGate(power: power, child: child!),
            home: _TickerProbe(onTick: () => ticks++),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (!initiallyActive) expect(ticks, 0);
        power.applyNativeWindowState(
          visible: true,
          minimized: false,
          focused: true,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(ticks, greaterThan(0));
        unawaited(
          showDialog<void>(
            context: navigator.currentContext!,
            builder: (_) => Dialog(child: _TickerProbe(onTick: () => ticks++)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        power.onWindowMinimize();
        await tester.pump();
        final paused = ticks;
        final businessBefore = businessTicks;
        await tester.pump(const Duration(seconds: 1));
        expect(ticks, paused);
        expect(businessTicks, greaterThan(businessBefore));
        power.onWindowRestore();
        power.onLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(
          ticks,
          paused,
          reason: 'Restore/resume without focus cannot unmute the Navigator',
        );
        power.applyNativeWindowState(
          visible: true,
          minimized: false,
          focused: true,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(ticks, greaterThan(paused));
        timer.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
        power.onWindowBlur();
      },
    );
  }
}

class _TickerProbe extends StatefulWidget {
  const _TickerProbe({required this.onTick});
  final VoidCallback onTick;
  @override
  State<_TickerProbe> createState() => _TickerProbeState();
}

class _TickerProbeState extends State<_TickerProbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(widget.onTick)
          ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 100, height: 100);
}
