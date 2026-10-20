import 'package:flutter/widgets.dart';
import 'app_power_manager.dart';

/// Blocks ordinary rendering, not Dart timers or background MES/OTA services.
mixin PowerFrameGate on WidgetsBinding {
  @override
  void initInstances() {
    super.initInstances();
    AppPowerManager.instance.indicatorsAnimationNotifier.addListener(
      _wakeFrames,
    );
  }

  @override
  bool get framesEnabled =>
      super.framesEnabled && AppPowerManager.instance.shouldAnimateIndicators;

  void _wakeFrames() {
    if (AppPowerManager.instance.shouldAnimateIndicators) scheduleFrame();
  }
}

class PowerWidgetsBinding extends WidgetsFlutterBinding with PowerFrameGate {}

class PowerTickerGate extends StatelessWidget {
  const PowerTickerGate({super.key, required this.child, this.power});
  final Widget child;
  final AppPowerManager? power;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable:
        (power ?? AppPowerManager.instance).indicatorsAnimationNotifier,
    builder: (_, active, child) => TickerMode(enabled: active, child: child!),
    child: child,
  );
}
