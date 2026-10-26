import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/plugins_scope.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/schedule/domain/entities/create_task_trigger_input.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/domain/entities/schedule_config.dart';
import 'package:syscat2/features/schedule/domain/entities/task_trigger.dart';
import 'package:syscat2/features/schedule/domain/entities/trigger_cycle_analysis.dart';
import 'package:syscat2/features/schedule/infrastructure/models/event_trigger_config_mapper.dart';
import 'package:syscat2/features/schedule/infrastructure/repositories/local_task_trigger_repository.dart';
import 'package:syscat2/features/schedule/presentation/cubits/schedule_cubit.dart';
import 'package:syscat2/features/schedule/presentation/cubits/schedule_state.dart';
import 'package:syscat2/features/schedule/presentation/pages/schedule_page.dart';
import 'package:syscat2/features/schedule/presentation/widgets/trigger_dialog_actions.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/schedule/domain/repositories/task_trigger_repository.dart';
import 'package:syscat2/features/schedule/domain/usecases/analyze_task_trigger.dart';
import 'package:syscat2/features/schedule/domain/usecases/create_task_trigger.dart';
import 'package:syscat2/features/schedule/domain/usecases/delete_task_trigger.dart';
import 'package:syscat2/features/schedule/domain/usecases/rotate_webhook_token.dart';
import 'package:syscat2/features/schedule/domain/usecases/set_task_trigger_enabled.dart';
import 'package:syscat2/features/schedule/domain/usecases/watch_task_triggers.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';

const _hmac = HmacWebhookVerification(
  header: 'X-Hub-Signature-256',
  algorithm: WebhookSignatureAlgorithm.sha512,
  encoding: WebhookSignatureEncoding.base64,
  prefix: 'sha512=',
);

void main() {
  group('EventTriggerConfigMapper für Webhooks', () {
    test('schickt weder Token noch ein leeres Geheimnis', () {
      final document = EventTriggerConfigMapper.toDocument(
        const EventTriggerConfig(
          source: EventTriggerSource.webhookReceived,
          webhook: WebhookConfig(
            token: 'vom-client',
            validationParameter: ' validationToken ',
          ),
        ),
      );

      expect(document['webhook'], {
        'verification': {'kind': 'none'},
        'validationParameter': 'validationToken',
      });
    });

    test('schickt Signaturprüfung und Geheimnis beim Anlegen', () {
      final document = EventTriggerConfigMapper.toDocument(
        const EventTriggerConfig(
          source: EventTriggerSource.webhookReceived,
          webhook: WebhookConfig(verification: _hmac, secret: 'geheim'),
        ),
      );

      expect(document['webhook'], {
        'verification': {
          'kind': 'hmac',
          'header': 'X-Hub-Signature-256',
          'algorithm': 'sha512',
          'encoding': 'base64',
          'prefix': 'sha512=',
        },
        'validationParameter': '',
        'secret': 'geheim',
      });
    });

    test('liest Token und Prüfung zurück, nie ein Geheimnis', () {
      final restored = EventTriggerConfigMapper.fromDocument({
        'source': 'webhookReceived',
        'webhook': {
          'token': 'abc',
          'verification': {
            'kind': 'hmac',
            'header': 'x-signature',
            'algorithm': 'sha256',
            'encoding': 'hex',
            'prefix': '',
          },
          'validationParameter': 'validationToken',
        },
      })!;

      final webhook = restored.webhook!;
      expect(webhook.token, 'abc');
      expect(webhook.secret, isEmpty);
      expect(webhook.validationParameter, 'validationToken');
      expect(
        (webhook.verification as HmacWebhookVerification).header,
        'x-signature',
      );
    });

    test('Quellen ohne Webhook haben keine Webhook-Einstellungen', () {
      final restored = EventTriggerConfigMapper.fromDocument({
        'source': 'fileCreated',
      })!;
      expect(restored.webhook, isNull);
      expect(
        EventTriggerConfigMapper.toDocument(restored).containsKey('webhook'),
        isFalse,
      );
    });

    test(
      'eine Signaturprüfung ist ohne Kopfzeile oder Geheimnis unvollständig',
      () {
        expect(const WebhookConfig().isComplete, isTrue);
        expect(const WebhookConfig(verification: _hmac).isComplete, isFalse);
        expect(
          const WebhookConfig(verification: _hmac, secret: 'x').isComplete,
          isTrue,
        );
        expect(
          const WebhookConfig(
            verification: HmacWebhookVerification(header: ' '),
            secret: 'x',
          ).isComplete,
          isFalse,
        );
      },
    );
  });

  group('LocalTaskTriggerRepository für Webhooks', () {
    test('baut die Adresse aus Runtime-Adresse, Kennung und Token', () async {
      final triggers = await _repository(
        Uri.parse('https://novooa.example.com'),
        _client(items: [_webhookItem('t1', 'tok')]),
      ).watchTriggers().first;

      expect(
        triggers.single.webhookUrl,
        'https://novooa.example.com/hooks/t1/tok',
      );
    });

    test('behält einen Pfad vor der Runtime bei', () async {
      final triggers = await _repository(
        Uri.parse('https://example.com/novooa/'),
        _client(items: [_webhookItem('t1', 'tok')]),
      ).watchTriggers().first;

      expect(
        triggers.single.webhookUrl,
        'https://example.com/novooa/hooks/t1/tok',
      );
    });

    test('andere Auslöser haben keine Adresse', () async {
      final triggers = await _repository(
        Uri.parse('https://novooa.example.com'),
        _client(
          items: [
            {
              'id': 'f1',
              'teamId': 'team',
              'taskId': 'task',
              'taskTitle': 'A',
              'type': 'event',
              'enabled': true,
              'eventConfig': {'source': 'fileCreated'},
              'policy': {},
            },
          ],
        ),
      ).watchTriggers().first;

      expect(triggers.single.webhookUrl, isNull);
    });

    test('erneuert das Token über die Runtime', () async {
      final client = _client();
      await _repository(
        Uri.parse('https://x.example'),
        client,
      ).rotateWebhookToken('t1');

      expect(client.posts.single.$1, '/v1/task-triggers/t1/webhook-token');
      expect(client.posts.single.$2, isEmpty);
    });

    test('schickt die Konfiguration beim Anlegen samt Geheimnis', () async {
      final client = _client();
      await _repository(Uri.parse('https://x.example'), client).createTrigger(
        const CreateTaskTriggerInput(
          taskId: 'task',
          taskTitle: 'A',
          type: TriggerType.event,
          event: EventTriggerConfig(
            source: EventTriggerSource.webhookReceived,
            webhook: WebhookConfig(verification: _hmac, secret: 'geheim'),
          ),
        ),
      );

      final body = client.posts.single.$2;
      expect((body['eventConfig'] as Map)['source'], 'webhookReceived');
      expect(
        ((body['eventConfig'] as Map)['webhook'] as Map)['secret'],
        'geheim',
      );
    });
  });

  group('ScheduleCubit', () {
    ScheduleCubit cubitFor(_TriggerRepository repository) {
      return ScheduleCubit(
        watchTaskTriggers: WatchTaskTriggers(repository),
        createTaskTrigger: CreateTaskTrigger(repository),
        setTaskTriggerEnabled: SetTaskTriggerEnabled(repository),
        deleteTaskTrigger: DeleteTaskTrigger(repository),
        taskRepository: _TaskRepository(),
        analyzeTaskTrigger: AnalyzeTaskTrigger(repository),
        rotateWebhookToken: RotateWebhookToken(repository),
      );
    }

    test('erneuert das Token des gewählten Auslösers', () async {
      final repository = _TriggerRepository();
      final cubit = cubitFor(repository);
      addTearDown(cubit.close);

      await cubit.rotateWebhookToken(_webhookTrigger());

      expect(repository.rotated, ['t1']);
    });
  });

  group('Auslöser-Dialog und Karte', () {
    tearDown(() async => serviceLocator.reset());

    testWidgets('ein Webhook ohne Signaturprüfung wird direkt erstellt', (
      tester,
    ) async {
      final cubit = await _openEventForm(tester);
      await _chooseWebhook(tester);

      expect(find.text('Textfilter (optional)'), findsNothing);
      expect(find.text('Kopfzeile mit der Signatur'), findsNothing);

      await tester.tap(find.text('Auslöser erstellen'));
      await tester.pumpAndSettle();

      expect(cubit.created.single.source, EventTriggerSource.webhookReceived);
      expect(
        cubit.created.single.webhook!.verification,
        isA<NoWebhookVerification>(),
      );
    });

    testWidgets(
      'mit Signaturprüfung braucht der Dialog Kopfzeile und Geheimnis',
      (tester) async {
        final cubit = await _openEventForm(tester);
        await _chooseWebhook(tester);

        await tester.tap(find.text('Signatur prüfen (empfohlen)'));
        await tester.pumpAndSettle();
        expect(find.text('Kopfzeile mit der Signatur'), findsOneWidget);
        expect(_createAction(tester).onPressed, isNull);

        await tester.enterText(
          find.widgetWithText(TextField, 'Kopfzeile mit der Signatur'),
          'X-Signature',
        );
        await tester.pump();
        expect(
          _createAction(tester).onPressed,
          isNull,
          reason: 'Geheimnis fehlt noch',
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Geheimnis'),
          'geheim',
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Parameter der Einrichtungsprüfung (optional)',
          ),
          'validationToken',
        );
        await tester.pump();
        expect(_createAction(tester).onPressed, isNotNull);

        await tester.tap(find.text('Auslöser erstellen'));
        await tester.pumpAndSettle();

        final webhook = cubit.created.single.webhook!;
        final verification = webhook.verification as HmacWebhookVerification;
        expect(verification.header, 'X-Signature');
        expect(verification.algorithm, WebhookSignatureAlgorithm.sha256);
        expect(webhook.secret, 'geheim');
        expect(webhook.validationParameter, 'validationToken');
      },
    );

    testWidgets('die Karte zeigt die Adresse und kopiert sie', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final cubit = _Cubit(
        ScheduleState(
          status: ScheduleStatus.ready,
          tasks: [Task.empty()],
          triggers: [_webhookTrigger()],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('webhook-address')), findsOneWidget);
      expect(
        find.text('https://novooa.example.com/hooks/t1/tok'),
        findsOneWidget,
      );
      expect(find.textContaining('Ohne Signaturprüfung'), findsOneWidget);

      await tester.tap(find.byTooltip('Adresse kopieren'));
      await tester.pumpAndSettle();
      expect(copied, ['https://novooa.example.com/hooks/t1/tok']);
    });

    testWidgets('die Karte warnt bei http und meldet geprüfte Signaturen', (
      tester,
    ) async {
      final cubit = _Cubit(
        ScheduleState(
          status: ScheduleStatus.ready,
          tasks: [Task.empty()],
          triggers: [
            _webhookTrigger(
              url: 'http://192.168.0.5:8090/hooks/t1/tok',
              verification: _hmac,
            ),
          ],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      expect(find.textContaining('unverschlüsselt'), findsOneWidget);
      expect(find.textContaining('über ihre Signatur geprüft'), findsOneWidget);
    });

    testWidgets('eine neue Adresse wird erst nach Bestätigung erzeugt', (
      tester,
    ) async {
      final cubit = _Cubit(
        ScheduleState(
          status: ScheduleStatus.ready,
          tasks: [Task.empty()],
          triggers: [_webhookTrigger()],
        ),
      );
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(cubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Neue Adresse erzeugen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(cubit.rotated, isEmpty);

      await tester.tap(find.text('Neue Adresse erzeugen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neue Adresse'));
      await tester.pumpAndSettle();
      expect(cubit.rotated, ['t1']);
    });
  });
}

TriggerDialogAction _createAction(WidgetTester tester) =>
    tester.widget<TriggerDialogAction>(
      find.widgetWithText(TriggerDialogAction, 'Auslöser erstellen'),
    );

Future<void> _chooseWebhook(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<EventTriggerSource>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Webhook empfangen').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Auslöser erstellen'));
}

Future<_Cubit> _openEventForm(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final cubit = _Cubit(
    ScheduleState(status: ScheduleStatus.ready, tasks: [Task.empty()]),
  );
  await tester.pumpWidget(_app(cubit));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ersten Auslöser erstellen'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ereignis'));
  await tester.pumpAndSettle();
  return cubit;
}

Widget _app(_Cubit cubit) => withPlugins(_materialApp(cubit));

Widget _materialApp(_Cubit cubit) => MaterialApp(
  home: Scaffold(
    body: BlocProvider<ScheduleCubit>.value(
      value: cubit,
      child: const ScheduleView(),
    ),
  ),
);

TaskTrigger _webhookTrigger({
  String url = 'https://novooa.example.com/hooks/t1/tok',
  WebhookVerification verification = WebhookVerification.none,
}) => TaskTrigger(
  id: 't1',
  teamId: 'team',
  taskId: 'task',
  taskTitle: 'Bestellung verarbeiten',
  type: TriggerType.event,
  enabled: true,
  policy: TriggerRunPolicy.skipIfRunning,
  event: EventTriggerConfig(
    source: EventTriggerSource.webhookReceived,
    webhook: WebhookConfig(token: 'tok', verification: verification),
  ),
  webhookUrl: url,
);

Map<String, Object?> _webhookItem(String id, String token) => {
  'id': id,
  'teamId': 'team',
  'taskId': 'task',
  'taskTitle': 'Bestellung verarbeiten',
  'type': 'event',
  'enabled': true,
  'eventConfig': {
    'source': 'webhookReceived',
    'webhook': {
      'token': token,
      'verification': {'kind': 'none'},
      'validationParameter': '',
    },
  },
  'policy': {'ifRunning': 'skipIfRunning'},
};

class _Cubit extends Fake implements ScheduleCubit {
  _Cubit(this.state);
  @override
  final ScheduleState state;
  @override
  Stream<ScheduleState> get stream => const Stream.empty();
  final List<EventTriggerConfig> created = [];
  final List<String> rotated = [];
  int get creates => created.length;

  @override
  Future<TriggerCycleAnalysis> analyzeEventTrigger(
    Task task,
    EventTriggerConfig event,
  ) async => TriggerCycleAnalysis.none;

  @override
  Future<void> createEventTrigger(Task task, EventTriggerConfig event) async =>
      created.add(event);

  @override
  Future<void> rotateWebhookToken(TaskTrigger trigger) async =>
      rotated.add(trigger.id);

  @override
  Future<void> createTrigger(Task task, ScheduleConfig schedule) async {}
}

class _Client extends WorkspaceApiClient {
  _Client(this.items);
  final List<Map<String, Object?>> items;
  final List<(String, Map<String, Object?>)> posts = [];

  @override
  Future<Map<String, Object?>> get(String path) async => {'items': items};

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    posts.add((path, body));
    return const {};
  }

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}

_Client _client({List<Map<String, Object?>> items = const []}) =>
    _Client(items);

LocalTaskTriggerRepository _repository(Uri baseUri, _Client client) =>
    LocalTaskTriggerRepository(
      client,
      WorkspaceRealtimeChannel(Uri.parse('http://127.0.0.1:0'), client),
      baseUri,
    );

class _TriggerRepository implements TaskTriggerRepository {
  final List<String> rotated = [];

  @override
  Stream<List<TaskTrigger>> watchTriggers() => const Stream.empty();

  @override
  Future<TriggerCycleAnalysis> analyzeTrigger(
    CreateTaskTriggerInput input,
  ) async => TriggerCycleAnalysis.none;

  @override
  Future<void> createTrigger(CreateTaskTriggerInput input) async {}

  @override
  Future<void> setTriggerEnabled(String triggerId, bool enabled) async {}

  @override
  Future<void> deleteTrigger(String triggerId) async {}

  @override
  Future<void> rotateWebhookToken(String triggerId) async =>
      rotated.add(triggerId);
}

class _TaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks() => const Stream.empty();

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
