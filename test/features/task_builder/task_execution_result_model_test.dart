import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/task_execution_result_model.dart';

// Deckt eine zuvor gefundene Inkonsistenz ab: das Backend liefert für
// „Sammlung als Tabelle" einen `table`-typisierten Workflow-Ausgabewert
// (siehe `table-from-collection-node-executor.ts`), das Dart-Pendant
// `NodeOutputType` kannte diesen Typ aber nicht und ist stillschweigend auf
// `json` zurückgefallen (`orElse`) — der Typ ging also unbemerkt verloren.
void main() {
  test(
    'NodeOutputType.fromName erkennt "table" statt auf json zurückzufallen',
    () {
      expect(NodeOutputType.fromName('table'), NodeOutputType.table);
    },
  );

  test('NodeOutputValueModel.toDomain bewahrt den table-Typ samt Rohwert', () {
    final model = NodeOutputValueModel.fromJson({
      'type': 'table',
      'value': {
        'columns': ['Name', 'Alter'],
        'rows': [
          ['Ada', 36],
          ['Alan', 41],
        ],
      },
    });

    final value = model.toDomain();

    expect(value.type, NodeOutputType.table);
    expect(value.value, {
      'columns': ['Name', 'Alter'],
      'rows': [
        ['Ada', 36],
        ['Alan', 41],
      ],
    });
  });

  test('NodeOutputType.fromName fällt für wirklich unbekannte Typnamen '
      'weiterhin auf json zurück', () {
    expect(
      NodeOutputType.fromName('irgendwas-unbekanntes'),
      NodeOutputType.json,
    );
  });
}
