import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syscat2/features/task_builder/domain/entities/task_definition.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_definition_repository.dart';
import 'package:syscat2/features/task_builder/presentation/pages/task_builder_page.dart';

class _TestRepository implements TaskDefinitionRepository {
  _TestRepository(this._seed);

  TaskDefinition _seed;
  int saveCalls = 0;

  @override
  Future<TaskDefinition> loadDraft() async => _seed;

  @override
  Future<void> saveDraft(TaskDefinition taskDefinition) async {
    saveCalls++;
    _seed = taskDefinition;
  }

  TaskDefinition get current => _seed;
}

void main() {
  testWidgets('Aufgabe-Builder lädt Seed, fügt Baustein hinzu und speichert',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _TestRepository(
      TaskDefinition(
        id: 'draft.task',
        title: 'Testaufgabe',
        objective: 'Test objective',
        selectedNodeId: const NodeId('node.1'),
        nodes: const [
          WorkflowNode(
            id: NodeId('node.1'),
            primitive: WorkflowPrimitive.prompt,
            title: 'Start',
            description: 'Initialer Schritt.',
          ),
        ],
        edges: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskBuilderPage(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header sichtbar: AppBar mit Branding, Footer mit Speichern.
    expect(find.text('Bausteine Builder'), findsOneWidget);
    expect(find.text('Speichern'), findsOneWidget);
    expect(find.text('Verwerfen'), findsOneWidget);
    expect(find.text('Testaufgabe'), findsOneWidget);

    // Tab im AppBar antippen — fügt einen Baustein hinzu.
    await tester.tap(find.text('Werkzeug-Aufruf'));
    await tester.pumpAndSettle();

    // Seed hatte 1 Knoten, jetzt 2.
    expect(repository.current.nodes.length, 2);
    expect(repository.saveCalls, greaterThanOrEqualTo(1));
  });
}