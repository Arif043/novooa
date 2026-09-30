import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_code_editor.dart';

void main() {
  testWidgets('rendert den Text des übergebenen Controllers', (tester) async {
    final controller = CodeController(text: 'print(1)', language: python);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptCodeEditor(controller: controller, onChanged: (_) {}),
        ),
      ),
    );

    expect(_controllerTextIn(tester), 'print(1)');
  });
}

String _controllerTextIn(WidgetTester tester) {
  return tester.widget<CodeField>(find.byType(CodeField)).controller.text;
}
