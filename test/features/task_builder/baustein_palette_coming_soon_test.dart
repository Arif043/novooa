import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/plugins_scope.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/baustein_palette.dart';

void main() {
  testWidgets('Nur E-Mail ist anwählbar, andere Anbieter sind deaktiviert', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final added = <BausteinChoice>[];
    await tester.pumpWidget(
      withPlugins(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: BausteinPalette(onAdd: added.add),
            ),
          ),
        ),
      ),
    );

    for (final name in ['Telegram', 'Instagram', 'WhatsApp', 'SMS']) {
      final tile = find.widgetWithText(
        ListTile,
        '$name senden (Bald verfügbar)',
      );
      expect(tester.widget<ListTile>(tile).enabled, isFalse, reason: name);
    }
    await tester.tap(find.text('Telegram lesen (Bald verfügbar)'));
    expect(added, isEmpty);
    await tester.tap(find.text('E-Mail senden'));
    expect(added.single.kind, ChannelEventKind.email);
  });

  test('Anbieter nutzen ihr Markensymbol', () {
    const telegram = BausteinChoice(
      WorkflowPrimitive.sendChannelMessage,
      kind: ChannelEventKind.telegram,
    );
    expect(telegram.icon, SimpleIcons.telegram);
  });
}
