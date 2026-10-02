import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
import 'package:ja_mes_tool/widgets/glass_widgets.dart';

void main() {
  final power = AppPowerManager.instance;
  setUp(() {
    power.setEnableIdleSleep(true);
    power.resetForTesting();
  });
  tearDown(power.resetForTesting);

  const widgets = <String, Widget>{
    'MeshOrb': MeshOrb(
      color: Colors.blue,
      size: 20,
      duration: Duration(seconds: 1),
      travel: Offset(10, 10),
    ),
    'WaveIndicator': WaveIndicator(color: Colors.blue),
  };

  AnimationController controllerFor(WidgetTester tester, Widget widget) {
    final builder = tester.widget<AnimatedBuilder>(
      find.descendant(
        of: find.byType(widget.runtimeType),
        matching: find.byType(AnimatedBuilder),
      ),
    );
    return builder.animation as AnimationController;
  }

  for (final entry in widgets.entries) {
    for (final reverse in [false, true]) {
      testWidgets(
        '${entry.key} preserves ${reverse ? 'reverse' : 'forward'} leg across repeated blur/focus',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: entry.value)),
          );
          await tester.pump();
          final controller = controllerFor(tester, entry.value);
          if (reverse) {
            await tester.pump(controller.duration!);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 250));
          final expectedStatus = reverse
              ? AnimationStatus.reverse
              : AnimationStatus.forward;
          expect(controller.status, expectedStatus);

          for (var cycle = 0; cycle < 2; cycle++) {
            power.onWindowBlur();
            final frozen = controller.value;
            expect(controller.isAnimating, isFalse);
            await tester.pump(const Duration(seconds: 2));
            expect(controller.value, frozen);
            power.onWindowFocus();
            expect(controller.value, frozen);
            expect(controller.status, expectedStatus);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            expect(
              controller.value,
              reverse ? lessThan(frozen) : greaterThan(frozen),
            );
          }

          // Reaching the endpoint must still start the opposite leg.
          await tester.pump(controller.duration!);
          expect(
            controller.status,
            reverse ? AnimationStatus.forward : AnimationStatus.reverse,
          );
          expect(controller.isAnimating, isTrue);
          power.onWindowBlur();
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets(
      '${entry.key} created while blurred stays stopped until focus',
      (tester) async {
        power.onWindowBlur();
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: entry.value)));
        final controller = controllerFor(tester, entry.value);
        await tester.pump(const Duration(seconds: 2));
        expect(controller.isAnimating, isFalse);
        expect(controller.value, 0);
        power.onWindowFocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(controller.value, greaterThan(0));
        power.onWindowBlur();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('Idle freezes MeshOrb only and wake preserves its reverse leg', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Column(children: widgets.values.toList())),
      ),
    );
    await tester.pump();
    final mesh = controllerFor(tester, widgets['MeshOrb']!);
    final wave = controllerFor(tester, widgets['WaveIndicator']!);
    await tester.pump(mesh.duration!);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(mesh.status, AnimationStatus.reverse);
    power.resetForTesting(isIdle: true);
    final frozen = mesh.value;
    expect(mesh.isAnimating, isFalse);
    expect(wave.isAnimating, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(mesh.value, frozen);
    power.resetForTesting(isIdle: false);
    expect(mesh.status, AnimationStatus.reverse);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(mesh.value, lessThan(frozen));
    power.onWindowBlur();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
