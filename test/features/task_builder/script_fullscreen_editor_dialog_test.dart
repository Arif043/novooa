import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_fullscreen_editor_dialog.dart';

void main() {
  testWidgets(
    'zeigt denselben Skript-Inhalt (über den geteilten CodeController) im '
    'Vollbild-Dialog und schließt sich wieder',
    (tester) async {
      final controller = CodeController(text: 'ergebnis = 1', language: python);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_appWithOpenButton(controller, (_) {}));

      expect(find.text('Script bearbeiten'), findsNothing);

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();

      expect(find.text('Script bearbeiten'), findsOneWidget);
      expect(
        tester.widget<CodeField>(find.byType(CodeField)).controller,
        same(controller),
      );

      await tester.tap(find.byTooltip('Schließen'));
      await tester.pumpAndSettle();

      expect(find.text('Script bearbeiten'), findsNothing);
    },
  );
}

Widget _appWithOpenButton(
  CodeController controller,
  ValueChanged<String> onChanged,
) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showScriptFullscreenEditor(
            context,
            controller: controller,
            onChanged: onChanged,
          ),
          child: const Text('Öffnen'),
        ),
      ),
    ),
  );
}
