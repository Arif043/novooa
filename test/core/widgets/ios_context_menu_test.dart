import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/ios_context_menu.dart';

void main() {
  Future<List<String>> pumpMenu(WidgetTester tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IosContextMenuButton<String>(
            tooltip: 'Menü',
            entries: const [
              IosContextMenuItem(value: 'a', icon: Icons.edit, label: 'Ändern'),
              IosContextMenuItem(
                value: 'b',
                icon: Icons.block,
                label: 'Gesperrt',
                enabled: false,
              ),
              IosContextMenuDivider(),
              IosContextMenuItem(
                value: 'c',
                icon: Icons.delete_outline,
                label: 'Löschen',
                isDestructive: true,
              ),
            ],
            onSelected: selected.add,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Menü'));
    await tester.pumpAndSettle();
    return selected;
  }

  testWidgets('meldet die gewählte Aktion', (tester) async {
    final selected = await pumpMenu(tester);

    await tester.tap(find.text('Ändern'));
    await tester.pumpAndSettle();

    expect(selected, ['a']);
  });

  testWidgets('gesperrte Einträge lösen nichts aus, destruktive sind rot', (
    tester,
  ) async {
    final selected = await pumpMenu(tester);
    final context = tester.element(find.text('Löschen'));
    final deleteText = tester.widget<Text>(find.text('Löschen'));

    expect(deleteText.style?.color, Theme.of(context).colorScheme.error);
    await tester.tap(find.text('Gesperrt'));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });
}
