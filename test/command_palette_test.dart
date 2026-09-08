import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/theme/styles_win11.dart';
import 'package:ja_mes_tool/widgets/command_palette.dart';

void main() {
  testWidgets('renders and selects a command from the palette', (tester) async {
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCommandPalette(
                context,
                colors: win11DarkColors,
                items: [
                  CommandPaletteItem(
                    label: 'Open test record',
                    icon: Icons.fact_check,
                    onSelect: () => selected = true,
                  ),
                ],
              ),
              child: const Text('Open palette'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open palette'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Open test record'), findsOneWidget);

    await tester.tap(find.text('Open test record'));
    await tester.pumpAndSettle();

    expect(selected, isTrue);
  });
}
