import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node_outputs.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_output_types.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

const _team = TeamworkNodeConfig(
  instruction: 'Prüfe den Vertrag {{vertrag}}.',
  languageModelId: 'gemini',
  members: [
    TeamMember(
      employeeId: 'e1',
      responsibility: 'Recht',
      languageModelId: 'm1',
    ),
    TeamMember(employeeId: 'e2', responsibility: 'Zahlen'),
  ],
  outputFields: [
    StructuredOutputField(
      name: 'risiko',
      description: 'Höhe',
      type: StructuredFieldType.number,
    ),
    StructuredOutputField(
      name: 'faellig',
      description: '',
      type: StructuredFieldType.datetime,
    ),
    StructuredOutputField(
      name: 'bericht',
      description: '',
      type: StructuredFieldType.file,
      fileFormat: OutputFileFormat.csv,
    ),
  ],
);

void main() {
  final mapper = NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );

  group('TeamworkNodeConfig', () {
    test('wird verlustfrei gespeichert und gelesen', () {
      final document = mapper.toDocument(_team);

      expect(document['primitive'], 'teamwork');
      expect((document['members'] as List).first, {
        'employeeId': 'e1',
        'responsibility': 'Recht',
        'languageModelId': 'm1',
      });
      expect(
        (document['outputFields'] as List).last,
        containsPair('fileFormat', 'csv'),
      );
      expect(mapper.fromDocument(document), _team);
    });

    test('nimmt höchstens fünf verschiedene Mitarbeiter auf', () {
      var config = TeamworkNodeConfig.initial().addMember('a').addMember('a');
      expect(config.members.map((member) => member.employeeId), ['a']);

      for (final id in ['b', 'c', 'd', 'e', 'f']) {
        config = config.addMember(id);
      }
      expect(config.members, hasLength(TeamworkNodeConfig.maximumMembers));
      expect(config.canAddMember, isFalse);
      expect(
        config.removeMember('c').members.map((member) => member.employeeId),
        ['a', 'b', 'd', 'e'],
      );
    });

    test('jedes Feld wird ein Ausgabewert mit seinem Typ', () {
      expect(hasFlatOutputFields(_team), isTrue);
      expect(outputKeysOf(_team), ['risiko', 'faellig', 'bericht']);
      expect(typedFlatOutputFieldsOf(_team).map((field) => field.type), [
        NodeOutputType.number,
        NodeOutputType.datetime,
        NodeOutputType.file,
      ]);
    });
  });

  group('TaskBuilderCubit', () {
    late TaskBuilderCubit cubit;
    late NodeId nodeId;

    TeamworkNodeConfig config() =>
        (cubit.state as TaskBuilderLoaded).editingTask.nodes.single.config
            as TeamworkNodeConfig;

    setUp(() async {
      final repository = _TaskRepository();
      cubit = TaskBuilderCubit(repository: repository);
      await cubit.load(repository.saved);
      await cubit.addConnectedNode(primitive: WorkflowPrimitive.teamwork);
      nodeId = (cubit.state as TaskBuilderLoaded).editingTask.nodes.single.id;
    });

    tearDown(() => cubit.close());

    test('ein neuer Baustein startet ohne Team mit einem leeren Feld', () {
      expect(config(), TeamworkNodeConfig.initial());
    });

    test('updateTeamworkInstruction ändert die Anweisung', () async {
      await cubit.updateTeamworkInstruction(nodeId, 'Los');
      expect(config().instruction, 'Los');
    });

    test(
      'updateTeamworkLanguageModel ändert das Modell des Orchestrators',
      () async {
        await cubit.updateTeamworkLanguageModel(nodeId, 'gemini');
        expect(config().languageModelId, 'gemini');
      },
    );

    test(
      'addTeamMember, updateTeamMember und removeTeamMember pflegen das Team',
      () async {
        await cubit.addTeamMember(nodeId, 'e1');
        await cubit.updateTeamMember(
          nodeId,
          const TeamMember(
            employeeId: 'e1',
            responsibility: 'Recht',
            languageModelId: 'm1',
          ),
        );
        expect(config().members.single.responsibility, 'Recht');
        expect(config().members.single.languageModelId, 'm1');

        await cubit.removeTeamMember(nodeId, 'e1');
        expect(config().members, isEmpty);
      },
    );

    test('Ergebnisfelder bekommen eindeutige Namen', () async {
      await cubit.addTeamworkOutputField(nodeId);
      const field = StructuredOutputField(name: 'summe', description: '');
      await cubit.updateTeamworkOutputField(
        nodeId: nodeId,
        fieldIndex: 0,
        field: field,
      );
      await cubit.updateTeamworkOutputField(
        nodeId: nodeId,
        fieldIndex: 1,
        field: field,
      );

      expect(config().outputFields.map((field) => field.name), [
        'summe',
        isNot('summe'),
      ]);

      await cubit.removeTeamworkOutputField(nodeId: nodeId, fieldIndex: 1);
      expect(config().outputFields, hasLength(1));
    });
  });
}

class _TaskRepository implements TaskRepository {
  Task saved = const Task(
    id: 'task.team',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.0'),
    graph: WorkflowGraph(nodes: [], edges: []),
  );

  @override
  Stream<List<Task>> watchTasks() => Stream.value([saved]);

  @override
  Future<void> saveTask(Task task) async => saved = task;

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
}
