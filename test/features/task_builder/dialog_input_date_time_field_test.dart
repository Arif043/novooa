import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_output_types.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/dialog_input_field_editor.dart';

void main() {
  test('ein Datumsfeld liefert Datum/Zeit, ein Uhrzeitfeld Text', () {
    expect(
      dialogFieldOutputType(DialogInputFieldType.date),
      NodeOutputType.datetime,
    );
    expect(
      dialogFieldOutputType(DialogInputFieldType.time),
      NodeOutputType.string,
    );
  });

  testWidgets('der Datentyp lässt sich auf Datum und Uhrzeit stellen', (
    tester,
  ) async {
    DialogInputField? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DialogInputFieldEditor(
            field: const DialogInputField(
              name: 'termin',
              type: DialogInputFieldType.string,
            ),
            canRemove: false,
            onChanged: (field) => changed = field,
            onRemove: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    expect(find.text('Uhrzeit'), findsOneWidget);
    await tester.tap(find.text('Datum').last);
    await tester.pumpAndSettle();

    expect(changed?.type, DialogInputFieldType.date);
    expect(changed?.options, isEmpty);
  });
}
