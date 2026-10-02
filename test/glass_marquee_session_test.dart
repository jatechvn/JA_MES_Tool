import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
import 'package:ja_mes_tool/widgets/glass_widgets.dart';

void main() {
  group('AsymmetricMarqueeText Session Guard Tests', () {
    late AppPowerManager powerManager;

    setUp(() {
      powerManager = AppPowerManager.instance;
      powerManager.resetForTesting(
        isFocused: true,
        isVisible: true,
        isIdle: false,
      );
    });

    tearDown(() {
      powerManager.resetForTesting(
        isFocused: true,
        isVisible: true,
        isIdle: false,
      );
    });

    testWidgets(
      'Marquee pauses scrolling when window is blurred and resumes when focused',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100, // Small container to force overflow
                child: AsymmetricMarqueeText(
                  text:
                      'A very long serial number string that overflows container bounds easily',
                  pauseStart: const Duration(milliseconds: 50),
                  pauseEnd: const Duration(milliseconds: 50),
                ),
              ),
            ),
          ),
        );

        // Initial pump
        await tester.pump();
        expect(powerManager.shouldAnimateMarquee, isTrue);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 300));
        final scrollController = tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .controller!;
        expect(scrollController.offset, greaterThan(0));

        // Blur window
        powerManager.onWindowBlur();
        final frozenOffset = scrollController.offset;
        await tester.pump();
        expect(powerManager.shouldAnimateMarquee, isFalse);

        // Advance time while blurred - verify no crash, no active timers spinning out of control
        await tester.pump(const Duration(seconds: 15));
        expect(scrollController.offset, frozenOffset);
        expect(tester.binding.transientCallbackCount, 0);

        // Regain focus
        powerManager.onWindowFocus();
        await tester.pump();
        expect(powerManager.shouldAnimateMarquee, isTrue);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 300));
        expect(scrollController.offset, greaterThan(frozenOffset));

        // Cleanup for widget tester invariants
        powerManager.onWindowBlur();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
