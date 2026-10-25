import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_drive_item.dart';
import 'package:syscat2/features/integrations/google_drive/domain/google_drive_node_config.dart';
import 'package:syscat2/features/integrations/google_drive/google_drive_plugin.dart';
import 'package:syscat2/features/integrations/google_drive/presentation/widgets/google_drive_action_widget.dart';
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
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';

import '../google_accounts/google_account_test_doubles.dart';

const _account = GoogleAccount(
  id: 'konto-1',
  email: 'team@example.com',
  status: GoogleAccountStatus.active,
  sharedItems: [
    GoogleDriveItem(
      id: 'ordner-1',
      name: 'Rechnungen',
      mimeType: GoogleDriveItem.folderMimeType,
    ),
    GoogleDriveItem(
      id: 'datei-1',
      name: 'Preise.pdf',
      mimeType: 'application/pdf',
    ),
  ],
);

const _task = Task(
  id: 'task.drive',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.0'),
  graph: WorkflowGraph(nodes: [], edges: []),
);

void main() {
  setUp(registerGoogleDrivePlugin);
  tearDown(() {
    for (final module in PluginNodeModules.all) {
      if (module.typeId.startsWith('googleDrive.')) {
        PluginNodeModules.unregister(module.typeId);
      }
    }
  });

  final mapper = NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );

  test(
    'gespeichert als Primitive googleDrive mit Aktion, Konto und Eingaben',
    () {
      final config = const GoogleDriveNodeConfig(
        action: 'upload',
      ).copyWith(accountId: 'konto-1').withParam('folderId', 'ordner-1');

      final document = mapper.toDocument(config);

      expect(document, {
        'primitive': 'googleDrive',
        'action': 'upload',
        'accountId': 'konto-1',
        'params': {'folderId': 'ordner-1'},
      });
      expect(mapper.fromDocument(document), config);
    },
  );

  test('Ausgaben passen zu den Werten des Backends', () {
    const upload = GoogleDriveNodeConfig(action: 'upload');
    const read = GoogleDriveNodeConfig(action: 'read');

    expect(primaryOutputTypeOf(upload), NodeOutputType.string);
    expect(outputFieldsOf(upload), [
      'driveFileId',
      'name',
      'mimeType',
      'sizeBytes',
    ]);
    expect(primaryOutputTypeOf(read), NodeOutputType.file);
    expect(outputFieldsOf(read), ['driveFileId', 'name', 'mimeType']);
  });

  test('die Palette zeigt übersetzte Titel', () {
    expect(
      PluginNodeModules.byTypeId('googleDrive.upload')?.title,
      'In Google Drive speichern',
    );
    expect(
      PluginNodeModules.byTypeId('googleDrive.read')?.title,
      'Aus Google Drive lesen',
    );
  });

  group('Formular', () {
    late TaskBuilderCubit builder;

    Future<void> pumpNode(WidgetTester tester, String action) async {
      builder = TaskBuilderCubit(repository: _TaskRepository());
      await builder.load(_task);
      await builder.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        pluginTypeId: 'googleDrive.$action',
      );
      final id =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single.id;
      await builder.updatePluginNode(
        id,
        (config) =>
            (config as GoogleDriveNodeConfig).copyWith(accountId: 'konto-1'),
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: builder),
            BlocProvider(
              create: (_) => googleAccountsCubitFor(
                FakeGoogleAccountRepository(const [_account]),
              )..load(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
                  builder: (context, state) => GoogleDriveActionWidget(
                    node: (state as TaskBuilderLoaded).editingTask.nodes.single,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    GoogleDriveNodeConfig current() =>
        (builder.state as TaskBuilderLoaded).editingTask.nodes.single.config
            as GoogleDriveNodeConfig;

    // Der Cubit speichert verzögert; das läuft vor dem Ende aus, sonst bliebe ein Timer offen.
    void widgetTest(
      String description,
      Future<void> Function(WidgetTester) body,
    ) {
      testWidgets(description, (tester) async {
        await body(tester);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox.shrink());
        await builder.close();
      });
    }

    widgetTest('Speichern bietet „Meine Ablage“ und freigegebene Ordner an', (
      tester,
    ) async {
      await pumpNode(tester, 'upload');

      expect(find.text('team@example.com'), findsOneWidget);
      await tester.tap(find.text('Meine Ablage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rechnungen').last);
      await tester.pumpAndSettle();

      expect(current().params['folderId'], 'ordner-1');
    });

    widgetTest('Lesen wählt eine freigegebene Datei oder eine Datei-ID', (
      tester,
    ) async {
      await pumpNode(tester, 'read');

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preise.pdf').last);
      await tester.pumpAndSettle();
      expect(current().params['fileId'], 'datei-1');

      await tester.tap(find.text('Preise.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Datei-ID aus einem vorherigen Baustein').last,
      );
      await tester.pumpAndSettle();

      expect(current().params, {'fileSource': 'expression'});
      expect(find.text('Datei-ID'), findsOneWidget);
    });
  });
}

class _TaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks() => Stream.value([_task]);

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
}
