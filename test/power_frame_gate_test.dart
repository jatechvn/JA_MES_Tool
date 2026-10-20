import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
import 'package:ja_mes_tool/modules/services/power_binding.dart';

class _PowerTestBinding extends AutomatedTestWidgetsFlutterBinding
    with PowerFrameGate {}

void main() {
  final binding = _PowerTestBinding();
  final power = AppPowerManager.instance;
  setUp(() => power.resetForTesting());
  tearDown(() => power.resetForTesting());

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
