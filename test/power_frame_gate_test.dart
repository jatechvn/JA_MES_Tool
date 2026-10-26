import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
import 'package:ja_mes_tool/modules/services/power_binding.dart';

class _PowerTestBinding extends AutomatedTestWidgetsFlutterBinding
    with PowerFrameGate {
  bool rasterized = true;

  // The widget-test engine does not rasterize native Windows surfaces.
  @override
  bool get firstFrameRasterized => rasterized;
}

void main() {
  final binding = _PowerTestBinding();
  final power = AppPowerManager.instance;
  setUp(() {
    binding.rasterized = true;
    power.resetForTesting();
  });
  tearDown(() {
    binding.rasterized = true;
    power.resetForTesting();
  });

  testWidgets(
    'hidden startup can schedule the first raster without granting focus',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      binding.rasterized = false;
      power.resetForTesting(isFocused: false, isVisible: false);
      expect(power.shouldAnimateIndicators, isFalse);
      expect(
        binding.framesEnabled,
        isTrue,
        reason:
            'Win32 Show waits for the first raster; hidden state cannot block it',
      );
      binding.scheduleFrame();
      expect(binding.hasScheduledFrame, isTrue);
      await tester.pump();

      binding.rasterized = true;
      expect(binding.framesEnabled, isFalse);
      binding.scheduleFrame();
      expect(
        binding.hasScheduledFrame,
        isFalse,
        reason:
            'The bootstrap exception must end immediately after first raster',
      );
      power.applyNativeWindowState(
        visible: true,
        minimized: false,
        focused: false,
      );
      expect(binding.framesEnabled, isFalse);
      power.applyNativeWindowState(
        visible: true,
        minimized: false,
        focused: true,
      );
      expect(binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      power.resetForTesting();
    },
  );

  testWidgets(
    'inactive frames stop while background timers keep working; native focus paints dirty UI',
    (tester) async {
      var builds = 0;
      var timerTicks = 0;
      await tester.pumpWidget(
        _TimerProbe(onBuild: () => builds++, onTimer: () => timerTicks++),
      );
      await tester.pump(const Duration(milliseconds: 60));
      power.onWindowBlur();
      await tester.pump(); // One previously queued frame is allowed to settle.
      final pausedBuilds = builds;
      final ticksBefore = timerTicks;
      await tester.pump(const Duration(seconds: 1));
      expect(timerTicks, greaterThan(ticksBefore));
      expect(builds, pausedBuilds);
      expect(binding.framesEnabled, isFalse);

      power.onLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(
        builds,
        pausedBuilds,
        reason: 'Unlock without verified native focus stays gated',
      );
      power.applyNativeWindowState(
        visible: true,
        minimized: false,
        focused: true,
      );
      expect(binding.hasScheduledFrame, isTrue);
      await tester.pump();
      expect(builds, greaterThan(pausedBuilds));
      expect(binding.framesEnabled, isTrue);

      power.resetForTesting(isIdle: true);
      final idleBuilds = builds;
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        builds,
        greaterThan(idleBuilds),
        reason: 'Focused idle must remain responsive',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _TimerProbe extends StatefulWidget {
  const _TimerProbe({required this.onBuild, required this.onTimer});
  final VoidCallback onBuild;
  final VoidCallback onTimer;
  @override
  State<_TimerProbe> createState() => _TimerProbeState();
}

class _TimerProbeState extends State<_TimerProbe> {
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      widget.onTimer();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return const SizedBox();
  }
}
