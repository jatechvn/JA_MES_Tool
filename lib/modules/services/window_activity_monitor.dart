import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'app_power_manager.dart';

typedef WindowActivitySnapshot = ({bool visible, bool minimized, bool focused});

/// Verifies event hints and recovers focus/visibility events missed at unlock.
class WindowActivityMonitor with WindowListener {
  WindowActivityMonitor({
    AppPowerManager? power,
    Future<WindowActivitySnapshot> Function()? readState,
    this.pollInterval = const Duration(seconds: 2),
    this.readTimeout = const Duration(seconds: 1),
  }) : power = power ?? AppPowerManager.instance,
       _readState = readState ?? _readNativeState;

  final AppPowerManager power;
  final Duration pollInterval;
  final Duration readTimeout;
  final Future<WindowActivitySnapshot> Function() _readState;
  Timer? _poll;
  bool _disposed = false;
  bool _reading = false;
  bool _readAgain = false;
  int _epoch = 0;

  static Future<WindowActivitySnapshot> _readNativeState() async {
    final states = await Future.wait([
      windowManager.isVisible(),
      windowManager.isMinimized(),
      windowManager.isFocused(),
    ]);
    return (visible: states[0], minimized: states[1], focused: states[2]);
  }

  void start() {
    if (_disposed || _poll != null) return;
    power.onWindowBlur();
    unawaited(reconcile());
    _poll = Timer.periodic(pollInterval, (_) => unawaited(reconcile()));
  }

  Future<void> reconcile() async {
    if (_disposed) return;
    if (_reading) {
      _readAgain = true;
      return;
    }
    _reading = true;
    try {
      do {
        _readAgain = false;
        final epoch = _epoch;
        try {
          final state = await _readState().timeout(readTimeout);
          if (!_disposed && epoch == _epoch) {
            power.applyNativeWindowState(
              visible: state.visible,
              minimized: state.minimized,
              focused: state.focused,
            );
          }
        } catch (_) {
          if (!_disposed && epoch == _epoch) power.onWindowBlur();
        }
      } while (!_disposed && _readAgain);
    } finally {
      _reading = false;
    }
  }

  void onLifecycleStateChanged(AppLifecycleState state) {
    if (_disposed) return;
    _epoch++;
    power.onLifecycleStateChanged(state);
    // While locked/hidden, polling can recover missed events on return.
    if (state == AppLifecycleState.resumed) unawaited(reconcile());
  }

  @override
  void onWindowFocus() {
    if (_disposed) return;
    _epoch++;
    power.onWindowBlur();
    unawaited(reconcile());
  }

  @override
  void onWindowBlur() {
    if (_disposed) return;
    _epoch++;
    power.onWindowBlur();
  }

  @override
  void onWindowMinimize() {
    if (_disposed) return;
    _epoch++;
    power.onWindowMinimize();
  }

  @override
  void onWindowRestore() {
    if (_disposed) return;
    _epoch++;
    power.onWindowBlur();
    unawaited(reconcile());
  }

  void dispose() {
    _disposed = true;
    _epoch++;
    _poll?.cancel();
    _poll = null;
  }
}
