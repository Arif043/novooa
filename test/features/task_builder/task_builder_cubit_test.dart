import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class _InMemoryTaskRepository implements TaskRepository {
  _InMemoryTaskRepository(this.savedTask);

  Task savedTask;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([savedTask]);

  @override
  Future<void> saveTask(Task task) async {
    savedTask = task;
  }

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
  }
}

Future<void> _closeAndExpectSaved(
  TaskBuilderCubit cubit,
  _InMemoryTaskRepository repository,
  Task task,
) async {
  await cubit.close();
  expect(repository.savedTask, task);
}

void main() {
  test(
    'updatePromptOutputType aktualisiert Bild-Prompts in Branch-Graphs',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.updatePromptOutputType(
        const NodeId('node.2'),
        PromptOutputType.image,
      );

      final state = cubit.state as TaskBuilderLoaded;
      final rootConfig =
          state.editingTask.nodes.first.config as ConditionalNodeConfig;
      final prompt = rootConfig.branches.first.graph.nodes.first;
      final promptConfig = prompt.config as PromptNodeConfig;

      expect(promptConfig.outputType, PromptOutputType.image);
      expect(promptConfig.choices, ['', '']);

      await cubit.close();
    },
  );

  test('removeNode entfernt Nodes aus Branch-Graphs', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.removeNode(const NodeId('node.2'));

    final state = cubit.state as TaskBuilderLoaded;
    final rootConfig =
        state.editingTask.nodes.first.config as ConditionalNodeConfig;
    final branch = rootConfig.branches.first;

    expect(branch.graph.nodes, isEmpty);
    expect(branch.graph.edges, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateNodeOutputName normalisiert Ausgabenamen', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateNodeOutputName(const NodeId('node.1'), '1 email!');

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.first.outputName, 'n1email');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateNodeOutputName macht doppelte Ausgabenamen eindeutig', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateNodeOutputName(const NodeId('node.2'), 'prompt1');

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.last.outputName, 'prompt1_2');

    await cubit.close();
  });

  test('swapNodes tauscht zwei Bausteine in der Reihenfolge', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.swapNodes(const NodeId('node.1'), const NodeId('node.2'));

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.map((node) => node.id.value), [
      'node.2',
      'node.1',
    ]);
    expect(state.editingTask.edges.single.from, const NodeId('node.2'));
    expect(state.editingTask.edges.single.to, const NodeId('node.1'));
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test(
    'addNode verwendet nach einem Löschen keine bereits belegte ID',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithThreePromptNodes());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.removeNode(const NodeId('node.1'));
      await cubit.addNodeToMainGraph(WorkflowPrimitive.script);

      final state = cubit.state as TaskBuilderLoaded;
      final nodeIds = state.editingTask.nodes.map((node) => node.id.value);
      expect(nodeIds.toSet(), hasLength(nodeIds.length));
      await _closeAndExpectSaved(cubit, repository, state.editingTask);
    },
  );

  test('addNode vergibt notificationSend keinen Ausgabenamen — reiner '
      'Seiteneffekt ohne fachlichen Rückgabewert', () async {
    final repository = _InMemoryTaskRepository(_taskWithTwoPromptNodes());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.addNodeToMainGraph(WorkflowPrimitive.notificationSend);

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.last.outputName, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test(
    'attachNodeFile speichert Storage-Dateiversion am Prompt-Node',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.attachNodeFile(
        nodeId: const NodeId('node.2'),
        attachment: _attachment,
      );

      var promptConfig = _branchPromptConfig(cubit);
      expect(promptConfig.attachments, [_attachment]);

      await cubit.detachNodeFile(
        nodeId: const NodeId('node.2'),
        attachmentId: _attachment.id,
      );

      final state = cubit.state as TaskBuilderLoaded;
      promptConfig = _branchPromptConfig(cubit);

      expect(promptConfig.attachments, isEmpty);
      await _closeAndExpectSaved(cubit, repository, state.editingTask);
    },
  );

  test(
    'attachNodeFile speichert Storage-Dateiversion am Script-Node',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithScriptNode());
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.attachNodeFile(
        nodeId: const NodeId('node.script'),
        attachment: _attachment,
      );

      final state = cubit.state as TaskBuilderLoaded;
      final config = state.editingTask.nodes.first.config as ScriptNodeConfig;

      expect(config.attachments, [_attachment]);
      await _closeAndExpectSaved(cubit, repository, state.editingTask);
    },
  );

  test(
    'load überschreibt keine entfernten Anhaenge mit Navigation-Kopien',
    () async {
      final staleTask = _taskWithScriptNodeWithAttachment();
      final repository = _InMemoryTaskRepository(staleTask);
      final firstCubit = TaskBuilderCubit(repository: repository);

      await firstCubit.load(staleTask);
      await firstCubit.detachNodeFile(
        nodeId: const NodeId('node.script'),
        attachmentId: _attachment.id,
      );
      await firstCubit.close();

      final reopenedCubit = TaskBuilderCubit(repository: repository);
      await reopenedCubit.load(staleTask);

      final state = reopenedCubit.state as TaskBuilderLoaded;
      final config = state.editingTask.nodes.first.config as ScriptNodeConfig;
      expect(config.attachments, isEmpty);
      await reopenedCubit.close();
    },
  );

  test('attachNodeKnowledge speichert Wissensnotiz am Prompt-Node', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.attachNodeKnowledge(
      nodeId: const NodeId('node.2'),
      attachment: _knowledgeAttachment,
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.knowledgeAttachments, [_knowledgeAttachment]);

    await cubit.detachNodeKnowledge(
      nodeId: const NodeId('node.2'),
      attachmentId: _knowledgeAttachment.id,
    );

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.knowledgeAttachments, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('attachNodeSkill haengt und loest Fähigkeit am Prompt-Node', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.attachNodeSkill(
      nodeId: const NodeId('node.2'),
      attachment: _skillAttachment,
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.skillAttachments, [_skillAttachment]);

    await cubit.attachNodeSkill(
      nodeId: const NodeId('node.2'),
      attachment: _skillAttachment,
    );
    promptConfig = _branchPromptConfig(cubit);
    expect(
      promptConfig.skillAttachments,
      hasLength(1),
      reason: 'gleicher Skill darf nicht doppelt angehängt werden',
    );

    await cubit.detachNodeSkill(
      nodeId: const NodeId('node.2'),
      attachmentId: _skillAttachment.id,
    );

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.skillAttachments, isEmpty);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('assignNodeEmployee weist einen Mitarbeiter zu und wieder ab', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.assignNodeEmployee(
      nodeId: const NodeId('node.2'),
      employeeId: 'employee.1',
    );

    var promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.employeeId, 'employee.1');

    await cubit.unassignNodeEmployee(nodeId: const NodeId('node.2'));

    final state = cubit.state as TaskBuilderLoaded;
    promptConfig = _branchPromptConfig(cubit);
    expect(promptConfig.employeeId, isNull);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('ein Mitarbeiter ersetzt eigene Fähigkeiten und umgekehrt', () async {
    final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
    final cubit = TaskBuilderCubit(repository: repository);
    const nodeId = NodeId('node.2');

    await cubit.load(repository.savedTask);
    await cubit.attachNodeSkill(nodeId: nodeId, attachment: _skillAttachment);
    await cubit.assignNodeEmployee(nodeId: nodeId, employeeId: 'employee.1');
    var config = _branchPromptConfig(cubit);
    expect(config.employeeId, 'employee.1');
    expect(
      config.skillAttachments,
      isEmpty,
      reason: 'Mitarbeiter leert Skills',
    );

    await cubit.attachNodeSkill(nodeId: nodeId, attachment: _skillAttachment);
    config = _branchPromptConfig(cubit);
    expect(config.employeeId, isNull, reason: 'Skill entfernt den Mitarbeiter');
    expect(config.skillAttachments, [_skillAttachment]);
  });

  test(
    'das Entfernen der letzten Fähigkeit lässt einen Mitarbeiter bestehen',
    () async {
      final repository = _InMemoryTaskRepository(_taskWithBranchPrompt());
      final cubit = TaskBuilderCubit(repository: repository);
      const nodeId = NodeId('node.2');

      await cubit.load(repository.savedTask);
      await cubit.assignNodeEmployee(nodeId: nodeId, employeeId: 'employee.1');
      await cubit.detachNodeSkill(
        nodeId: nodeId,
        attachmentId: 'gibt-es-nicht',
      );

      expect(_branchPromptConfig(cubit).employeeId, 'employee.1');
    },
  );

  test('updateScript speichert Script-Code am Script-Node', () async {
    final repository = _InMemoryTaskRepository(_taskWithScriptNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateScript(const NodeId('node.script'), 'output = input');

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as ScriptNodeConfig;

    expect(config.script, 'output = input');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateHumanApproval speichert Freigabe-Anweisung', () async {
    final repository = _InMemoryTaskRepository(_taskWithApprovalNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateHumanApproval(
      const NodeId('node.approval'),
      (config) => config.copyWith(instruction: 'Bitte prüfen.'),
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as HumanApprovalNodeConfig;

    expect(config.instruction, 'Bitte prüfen.');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateDialogInput speichert Formularfelder', () async {
    final repository = _InMemoryTaskRepository(_taskWithDialogInputNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateDialogInput(
      const NodeId('node.dialog'),
      (config) => config.updateField(
        0,
        const DialogInputField(
          name: 'alter',
          type: DialogInputFieldType.integer,
        ),
      ),
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as DialogInputNodeConfig;

    expect(config.fields.single.name, 'alter');
    expect(config.fields.single.type, DialogInputFieldType.integer);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test(
    'updateDialogInputField macht einen Feldnamen graph-weit eindeutig',
    () async {
      final repository = _InMemoryTaskRepository(
        _taskWithDialogInputNode().copyWith(
          graph: _taskWithDialogInputNode().graph.copyWith(
            nodes: [
              ..._taskWithDialogInputNode().nodes,
              const WorkflowNode(
                id: NodeId('node.text'),
                title: 'Text',
                description: '',
                outputName: 'kundennummer',
                config: StringInputNodeConfig(value: ''),
              ),
            ],
          ),
        ),
      );
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.updateDialogInputField(
        nodeId: const NodeId('node.dialog'),
        fieldIndex: 0,
        field: const DialogInputField(
          name: 'kundennummer',
          type: DialogInputFieldType.string,
        ),
      );

      final state = cubit.state as TaskBuilderLoaded;
      final config =
          state.editingTask.nodes
                  .firstWhere((node) => node.id == const NodeId('node.dialog'))
                  .config
              as DialogInputNodeConfig;
      expect(config.fields.single.name, 'kundennummer_2');
      await cubit.close();
    },
  );

  test(
    'updatePromptStructuredField macht einen Feldnamen graph-weit eindeutig',
    () async {
      final repository = _InMemoryTaskRepository(
        const Task(
          id: 'task.structured',
          title: 'Aufgabe',
          objective: '',
          selectedNodeId: NodeId('node.prompt'),
          graph: WorkflowGraph(
            nodes: [
              WorkflowNode(
                id: NodeId('node.text'),
                title: 'Text',
                description: '',
                outputName: 'name',
                config: StringInputNodeConfig(value: ''),
              ),
              WorkflowNode(
                id: NodeId('node.prompt'),
                title: 'Prompt',
                description: '',
                config: PromptNodeConfig(
                  instruction: '',
                  outputType: PromptOutputType.structured,
                  choices: [],
                  structuredFields: [
                    StructuredOutputField(name: '', description: ''),
                  ],
                ),
              ),
            ],
            edges: [],
          ),
        ),
      );
      final cubit = TaskBuilderCubit(repository: repository);

      await cubit.load(repository.savedTask);
      await cubit.updatePromptStructuredField(
        nodeId: const NodeId('node.prompt'),
        fieldIndex: 0,
        field: const StructuredOutputField(name: 'name', description: ''),
      );

      final state = cubit.state as TaskBuilderLoaded;
      final config =
          state.editingTask.nodes
                  .firstWhere((node) => node.id == const NodeId('node.prompt'))
                  .config
              as PromptNodeConfig;
      expect(config.structuredFields.single.name, 'name_2');
      await cubit.close();
    },
  );

  test('updateMediaInput speichert Anweisung', () async {
    final repository = _InMemoryTaskRepository(_taskWithMediaInputNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateMediaInput(
      const NodeId('node.media'),
      (config) => config.copyWith(instruction: 'Fotografiere das Dokument.'),
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as MediaInputNodeConfig;

    expect(config.instruction, 'Fotografiere das Dokument.');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('Text vorlesen: Sprachmodell wählen setzt die Stimme zurück', () async {
    final repository = _InMemoryTaskRepository(_taskWithTextToSpeechNode());
    final cubit = TaskBuilderCubit(repository: repository);
    const nodeId = NodeId('node.speech');

    await cubit.load(repository.savedTask);
    await cubit.updateTextToSpeechLanguageModel(nodeId, 'lm-google');
    await cubit.updateTextToSpeechText(nodeId, 'Hallo');
    await cubit.updateTextToSpeechVoice(nodeId, 'Puck');
    await cubit.updateTextToSpeechLanguageModel(nodeId, 'lm-google');
    final sameModel = _speechConfig(cubit);
    await cubit.updateTextToSpeechLanguageModel(nodeId, 'lm-eleven');
    final otherModel = _speechConfig(cubit);
    await cubit.updateTextToSpeechLanguageModel(nodeId, '');
    final backToOnnx = _speechConfig(cubit);

    expect(sameModel.voiceId, 'Puck');
    expect(otherModel.voiceId, '');
    expect(otherModel.speechText, 'Hallo');
    expect(backToOnnx.usesLanguageModel, isFalse);
  });

  test('Sprache zu Text speichert Sprachmodell und Audioquelle', () async {
    final repository = _InMemoryTaskRepository(_taskWithSpeechToTextNode());
    final cubit = TaskBuilderCubit(repository: repository);
    const nodeId = NodeId('node.stt');

    await cubit.load(repository.savedTask);
    await cubit.updateSpeechToTextLanguageModel(nodeId, 'lm-1');
    await cubit.updateSpeechToTextAudio(nodeId, '{{aufnahme.value}}');

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as SpeechToTextNodeConfig;
    expect(config.languageModelId, 'lm-1');
    expect(config.audioTemplate, '{{aufnahme.value}}');
  });

  test('updateModelInference speichert die Modell-ID', () async {
    final repository = _InMemoryTaskRepository(_taskWithModelInferenceNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateModelInference(
      const NodeId('node.model'),
      'mobilenet-v3',
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as ModelInferenceNodeConfig;

    expect(config.modelId, 'mobilenet-v3');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('aktualisiert das Workflow-Mapping einer Modelleingabe', () async {
    final repository = _InMemoryTaskRepository(_taskWithModelInferenceNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.selectModelInference(
      const NodeId('node.model'),
      'mobilenet-v3',
      const [
        ModelInferenceInputMapping(
          modelInputName: 'pixel_values',
          workflowMapping: '',
          sourceType: 'tensor',
          dataType: 'float32',
          shape: [1],
        ),
      ],
    );
    await cubit.updateModelInferenceWorkflowMapping(
      const NodeId('node.model'),
      const ModelInferenceInputMapping(
        modelInputName: 'pixel_values',
        workflowMapping: '{{eingabe.value}}',
        sourceType: 'tensor',
        dataType: 'float32',
        shape: [1],
      ),
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as ModelInferenceNodeConfig;

    expect(config.inputMappings.single.modelInputName, 'pixel_values');
    expect(config.inputMappings.single.workflowMapping, '{{eingabe.value}}');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('aktualisiert mehrere Modelleingabe-Mappings gemeinsam', () async {
    final repository = _InMemoryTaskRepository(_taskWithModelInferenceNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateModelInferenceWorkflowMappings(
      const NodeId('node.model'),
      const [
        ModelInferenceInputMapping(
          modelInputName: 'input',
          workflowMapping: '{{text.value}}',
          sourceType: 'text',
          dataType: 'int64',
          shape: [1, 1],
        ),
        ModelInferenceInputMapping(
          modelInputName: 'input_lengths',
          workflowMapping: '{{text.value}}',
          sourceType: 'text',
          dataType: 'int64',
          shape: [1],
        ),
      ],
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as ModelInferenceNodeConfig;
    expect(
      config.inputMappings.map((mapping) => mapping.workflowMapping),
      everyElement('{{text.value}}'),
    );
  });

  test('aktualisiert ein Setting einer Modellinferenz', () async {
    final repository = _InMemoryTaskRepository(_taskWithModelInferenceNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateModelInferenceSetting(
      const NodeId('node.model'),
      const ModelInferenceSetting(name: 'scores_k', valueTemplate: '5'),
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as ModelInferenceNodeConfig;

    expect(config.settings.single.valueTemplate, '5');
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('updateWriteFile speichert Dateiname und Inhaltstyp', () async {
    final repository = _InMemoryTaskRepository(_taskWithWriteFileNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.updateWriteFileName(const NodeId('node.file'), 'bericht.md');
    await cubit.updateWriteFileContentType(
      const NodeId('node.file'),
      'text/markdown',
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as WriteFileNodeConfig;

    expect(config.fileName, 'bericht.md');
    expect(config.contentType, 'text/markdown');
    expect(config.fileId, isNull);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });

  test('selectExistingWriteFile speichert bestehende Datei als Ziel', () async {
    final repository = _InMemoryTaskRepository(_taskWithWriteFileNode());
    final cubit = TaskBuilderCubit(repository: repository);
    final attachment = _attachment.copyWith(id: 'file.1:version.2');

    await cubit.load(repository.savedTask);
    await cubit.selectExistingWriteFile(const NodeId('node.file'), attachment);

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as WriteFileNodeConfig;

    expect(config.fileName, attachment.displayName);
    expect(config.contentType, attachment.contentType);
    expect(config.fileId, 'file.1');

    await cubit.close();
  });

  test('selectNewWriteFile speichert neue Datei ohne Datei-ID', () async {
    final repository = _InMemoryTaskRepository(_taskWithWriteFileNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.selectNewWriteFile(
      nodeId: const NodeId('node.file'),
      fileName: 'report.md',
      folderId: 'ordner.1',
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config = state.editingTask.nodes.first.config as WriteFileNodeConfig;

    expect(config.fileName, 'report.md');
    expect(config.contentType, 'text/plain');
    expect(config.fileId, isNull);
    expect(config.folderId, 'ordner.1');

    await cubit.close();
  });

  test('selectReadFile speichert ausgewaehlte Datei-Version', () async {
    final repository = _InMemoryTaskRepository(_taskWithReadFileNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.selectReadFile(const NodeId('node.read'), _attachment);

    var state = cubit.state as TaskBuilderLoaded;
    var config = state.editingTask.nodes.first.config as ReadFileNodeConfig;
    expect(config.file, _attachment);

    await cubit.clearReadFile(const NodeId('node.read'));

    state = cubit.state as TaskBuilderLoaded;
    config = state.editingTask.nodes.first.config as ReadFileNodeConfig;
    expect(config.file, isNull);
    await _closeAndExpectSaved(cubit, repository, state.editingTask);
  });
}

const _attachment = NodeAttachment(
  id: 'file.briefing.v1',
  storagePath: 'users/u1/uploads/briefing.md',
  generation: '1',
  displayName: 'briefing.md',
  contentType: 'text/markdown',
  sizeBytes: 12000,
);

const _knowledgeAttachment = KnowledgeAttachment(
  knowledgeBaseId: 'default',
  noteId: 'note.1',
  title: 'Index',
  path: 'index.md',
);

const _skillAttachment = SkillAttachment(
  name: 'mails-freundlich-beantworten',
  description: 'Nutze diese Fähigkeit für Kundenmails.',
);

PromptNodeConfig _branchPromptConfig(TaskBuilderCubit cubit) {
  final state = cubit.state as TaskBuilderLoaded;
  final rootConfig =
      state.editingTask.nodes.first.config as ConditionalNodeConfig;
  return rootConfig.branches.first.graph.nodes.first.config as PromptNodeConfig;
}

Task _taskWithBranchPrompt() {
  return _taskWithRootBranch(
    id: 'task.3',
    branchGraph: const WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.2'),
          title: 'Prompt',
          description: 'Beschreibung',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithScriptNode() {
  return const Task(
    id: 'task.script',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.script'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.script'),
          title: 'Script',
          description: 'Beschreibung',
          config: ScriptNodeConfig(script: 'output = ""'),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithScriptNodeWithAttachment() {
  final task = _taskWithScriptNode();
  final node = task.nodes.single;
  return task.copyWith(
    graph: task.graph.copyWith(
      nodes: [
        node.copyWith(
          config: ScriptNodeConfig(
            script: (node.config as ScriptNodeConfig).script,
            attachments: const [_attachment],
          ),
        ),
      ],
    ),
  );
}

Task _taskWithTwoPromptNodes() {
  return const Task(
    id: 'task.references',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.1'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.1'),
          title: 'Prompt',
          description: 'Beschreibung',
          outputName: 'prompt1',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
        WorkflowNode(
          id: NodeId('node.2'),
          title: 'Prompt',
          description: 'Beschreibung',
          outputName: 'prompt2',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
      ],
      edges: [WorkflowEdge(from: NodeId('node.1'), to: NodeId('node.2'))],
    ),
  );
}

Task _taskWithThreePromptNodes() {
  final task = _taskWithTwoPromptNodes();
  return task.copyWith(
    graph: task.graph.copyWith(
      nodes: [
        ...task.nodes,
        const WorkflowNode(
          id: NodeId('node.3'),
          title: 'Prompt',
          description: 'Beschreibung',
          outputName: 'prompt3',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.text,
            choices: ['', ''],
          ),
        ),
      ],
      edges: [
        ...task.edges,
        const WorkflowEdge(from: NodeId('node.2'), to: NodeId('node.3')),
      ],
    ),
  );
}

Task _taskWithApprovalNode() {
  return const Task(
    id: 'task.approval',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.approval'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.approval'),
          title: 'Freigabe',
          description: 'Beschreibung',
          config: HumanApprovalNodeConfig(instruction: 'Prüfe das Ergebnis.'),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithDialogInputNode() {
  return const Task(
    id: 'task.dialog',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.dialog'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.dialog'),
          title: 'Formulareingabe',
          description: 'Beschreibung',
          config: DialogInputNodeConfig(
            instruction: 'Bitte fülle das Formular aus.',
            fields: [
              DialogInputField(
                name: 'antwort',
                type: DialogInputFieldType.string,
              ),
            ],
          ),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithMediaInputNode() {
  return const Task(
    id: 'task.media',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.media'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.media'),
          title: 'Bild hinzufügen',
          description: 'Beschreibung',
          config: MediaInputNodeConfig(
            instruction: 'Bitte füge ein Bild hinzu.',
          ),
        ),
      ],
      edges: [],
    ),
  );
}

TextToSpeechNodeConfig _speechConfig(TaskBuilderCubit cubit) {
  final state = cubit.state as TaskBuilderLoaded;
  return state.editingTask.nodes.first.config as TextToSpeechNodeConfig;
}

Task _taskWithTextToSpeechNode() {
  return const Task(
    id: 'task.speech',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.speech'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.speech'),
          title: 'Text vorlesen',
          description: 'Beschreibung',
          config: TextToSpeechNodeConfig(modelId: ''),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithSpeechToTextNode() {
  return const Task(
    id: 'task.stt',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.stt'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.stt'),
          title: 'Sprache zu Text',
          description: 'Beschreibung',
          config: SpeechToTextNodeConfig(modelId: ''),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithModelInferenceNode() {
  return const Task(
    id: 'task.model',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.model'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.model'),
          title: 'Modell ausführen',
          description: 'Beschreibung',
          config: ModelInferenceNodeConfig(modelId: ''),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithWriteFileNode() {
  return const Task(
    id: 'task.file',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.file'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.file'),
          title: 'Datei schreiben',
          description: 'Beschreibung',
          config: WriteFileNodeConfig(
            fileName: 'ausgabe.txt',
            contentType: 'text/plain',
          ),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithReadFileNode() {
  return const Task(
    id: 'task.read',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.read'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.read'),
          title: 'Datei lesen',
          description: 'Beschreibung',
          config: ReadFileNodeConfig(),
        ),
      ],
      edges: [],
    ),
  );
}

Task _taskWithRootBranch({
  required String id,
  required WorkflowGraph branchGraph,
  String branchId = 'branch.root',
  String branchLabel = 'Root',
}) {
  return Task(
    id: id,
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: const NodeId('node.1'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: const NodeId('node.1'),
          title: 'Verzweigung',
          description: 'Beschreibung',
          config: ConditionalNodeConfig(
            branches: [
              ConditionalBranch(
                id: branchId,
                label: branchLabel,
                graph: branchGraph,
              ),
            ],
          ),
        ),
      ],
      edges: [],
    ),
  );
}
