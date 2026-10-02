import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';

void main() {
  group('AppPowerManager Tests', () {
    late AppPowerManager manager;

    setUp(() {
      manager = AppPowerManager.create();
    });

    tearDown(() {
      manager.dispose();
    });

    test(
      'Initial state: window is focused, visible, not idle, all policies active',
      () {
        expect(manager.isWindowFocused, isTrue);
        expect(manager.isWindowVisible, isTrue);
        expect(manager.isUserIdle, isFalse);
        expect(manager.shouldAnimateBackground, isTrue);
        expect(manager.shouldAnimateIndicators, isTrue);
        expect(manager.shouldAnimateMarquee, isTrue);
        expect(manager.backgroundAnimationNotifier.value, isTrue);
        expect(manager.indicatorsAnimationNotifier.value, isTrue);
        expect(manager.marqueeAnimationNotifier.value, isTrue);
      },
    );

    test('onWindowBlur() pauses all animations', () {
      manager.onWindowBlur();

      expect(manager.isWindowFocused, isFalse);
      expect(manager.isWindowVisible, isTrue);
      expect(manager.shouldAnimateBackground, isFalse);
      expect(manager.shouldAnimateIndicators, isFalse);
      expect(manager.shouldAnimateMarquee, isFalse);
      expect(manager.backgroundAnimationNotifier.value, isFalse);
      expect(manager.indicatorsAnimationNotifier.value, isFalse);
      expect(manager.marqueeAnimationNotifier.value, isFalse);
    });

    test('onWindowFocus() resumes all animations', () {
      manager.onWindowBlur();
      expect(manager.shouldAnimateBackground, isFalse);

      manager.onWindowFocus();
      expect(manager.isWindowFocused, isTrue);
      expect(manager.isWindowVisible, isTrue);
      expect(manager.shouldAnimateBackground, isTrue);
      expect(manager.shouldAnimateIndicators, isTrue);
      expect(manager.shouldAnimateMarquee, isTrue);
      expect(manager.backgroundAnimationNotifier.value, isTrue);
    });

    test(
      'onWindowMinimize() marks window invisible and unfocused, pausing all animations',
      () {
        manager.onWindowMinimize();

        expect(manager.isWindowVisible, isFalse);
        expect(manager.isWindowFocused, isFalse);
        expect(manager.shouldAnimateBackground, isFalse);
        expect(manager.shouldAnimateIndicators, isFalse);
        expect(manager.shouldAnimateMarquee, isFalse);
      },
    );

    test(
      'onWindowRestore() restores visibility but does NOT grant focus until focused',
      () {
        manager.onWindowMinimize();
        expect(manager.isWindowVisible, isFalse);

        manager.onWindowRestore();
        expect(manager.isWindowVisible, isTrue);
        // Crucial: focus remains false until onWindowFocus or resumed occurs
        expect(manager.isWindowFocused, isFalse);
        expect(manager.shouldAnimateBackground, isFalse);
        expect(manager.shouldAnimateIndicators, isFalse);
        expect(manager.shouldAnimateMarquee, isFalse);

        manager.onWindowFocus();
        expect(manager.isWindowFocused, isTrue);
        expect(manager.shouldAnimateBackground, isTrue);
        expect(manager.shouldAnimateIndicators, isTrue);
        expect(manager.shouldAnimateMarquee, isTrue);
      },
    );

    test('AppLifecycleState mapping', () {
      manager.onLifecycleStateChanged(AppLifecycleState.inactive);
      expect(manager.isWindowFocused, isFalse);
      expect(manager.shouldAnimateBackground, isFalse);

      manager.onLifecycleStateChanged(AppLifecycleState.resumed);
      expect(manager.isWindowFocused, isTrue);
      expect(manager.isWindowVisible, isTrue);
      expect(manager.shouldAnimateBackground, isTrue);

      manager.onLifecycleStateChanged(AppLifecycleState.hidden);
      expect(manager.isWindowVisible, isFalse);
      expect(manager.isWindowFocused, isFalse);
      expect(manager.shouldAnimateBackground, isFalse);
    });

    test(
      'Idle sleep: pauses background only, keeps indicators and marquee running',
      () async {
        manager.setIdleTimeout(const Duration(milliseconds: 50));
        manager.onWindowFocus();

        expect(manager.shouldAnimateBackground, isTrue);
        expect(manager.shouldAnimateIndicators, isTrue);

        await Future.delayed(const Duration(milliseconds: 80));

        expect(manager.isUserIdle, isTrue);
        expect(
          manager.shouldAnimateBackground,
          isFalse,
          reason: 'Heavy background should pause on idle',
        );
        expect(
          manager.shouldAnimateIndicators,
          isTrue,
          reason: 'Status indicators should stay alive on idle',
        );
        expect(
          manager.shouldAnimateMarquee,
          isTrue,
          reason: 'Marquee text should stay alive on idle',
        );

        // User interaction wakes up background
        manager.recordUserInteraction();
        expect(manager.isUserIdle, isFalse);
        expect(manager.shouldAnimateBackground, isTrue);
      },
    );

    test(
      'Disabling idle sleep keeps background active regardless of inactivity',
      () async {
        manager.setEnableIdleSleep(false);
        manager.setIdleTimeout(const Duration(milliseconds: 50));
        manager.onWindowFocus();

        expect(manager.enableIdleSleep, isFalse);
        expect(manager.shouldAnimateBackground, isTrue);

        await Future.delayed(const Duration(milliseconds: 80));

        expect(manager.isUserIdle, isFalse);
        expect(
          manager.shouldAnimateBackground,
          isTrue,
          reason: 'Background must remain active when idle sleep is disabled',
        );
      },
    );
  });
}
