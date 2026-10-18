import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/domain/entities/create_communication_channel_input.dart';
import 'package:syscat2/features/communication/domain/entities/send_channel_message_input.dart';
import 'package:syscat2/features/communication/domain/repositories/communication_channel_repository.dart';
import 'package:syscat2/features/communication/domain/usecases/begin_microsoft_connection.dart';
import 'package:syscat2/features/communication/domain/usecases/create_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/delete_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/dispatch_fake_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/send_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/watch_communication_channels.dart';
import 'package:syscat2/features/communication/presentation/cubits/communication_cubit.dart';
import 'package:syscat2/features/communication/presentation/widgets/communication_settings_tab.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

class _FakeRepository implements CommunicationChannelRepository {
  _FakeRepository(this.channels, {this.failing = false});

  final List<CommunicationChannel> channels;
  final bool failing;
  int connections = 0;

  @override
  Stream<List<CommunicationChannel>> watchChannels() =>
      failing ? Stream.error(StateError('offline')) : Stream.value(channels);

  @override
  Future<String> beginMicrosoftConnection() async {
    connections++;
    // Kein Browser im Test: Der Fehler beendet den Ablauf vor dem Öffnen der Adresse.
    throw StateError('kein Browser im Test');
  }

  @override
  Future<void> createChannel(CreateCommunicationChannelInput input) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  @override
  Future<void> dispatchFakeMessage(String channelId) async {}

  @override
  Future<void> sendMessage(SendChannelMessageInput input) async {}
}

CommunicationChannel _mailbox({
  CommunicationChannelStatus status = CommunicationChannelStatus.active,
}) {
  return CommunicationChannel(
    id: 'c1',
    teamId: const TeamId('workspace'),
    createdByUid: 'u',
    provider: CommunicationProvider.microsoftGraph,
    kind: CommunicationChannelKind.email,
    label: 'Team Postfach',
    address: 'team@example.com',
    status: status,
    capabilities: const ChannelCapabilities(inbound: true, outbound: true),
    connectorId: 'c1',
  );
}

WorkspaceCapabilities _capabilities({required bool messaging}) {
  return WorkspaceCapabilities(
    assistant: true,
    dataCollections: true,
    modelCatalog: true,
    push: false,
    messagingChannels: messaging,
    skills: false,
    employees: false,
    connections: false,
    webhooks: false,
    scriptPackages: false,
  );
}

Future<_FakeRepository> _pump(
  WidgetTester tester, {
  required bool messaging,
  List<CommunicationChannel> channels = const [],
  bool failing = false,
}) async {
  final repository = _FakeRepository(channels, failing: failing);
  serviceLocator
    ..registerSingleton(_capabilities(messaging: messaging))
    ..registerFactory(
      () => CommunicationCubit(
        WatchCommunicationChannels(repository),
        CreateCommunicationChannel(repository),
        DeleteCommunicationChannel(repository),
        DispatchFakeChannelMessage(repository),
        SendChannelMessage(repository),
        BeginMicrosoftConnection(repository),
      ),
    );
  addTearDown(() async {
    await serviceLocator.unregister<WorkspaceCapabilities>();
    await serviceLocator.unregister<CommunicationCubit>();
  });
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: CommunicationSettingsTab())),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'lokale Variante: zeigt die Postfächer und bietet nur Postfach verbinden an',
    (tester) async {
      await _pump(tester, messaging: false, channels: [_mailbox()]);

      expect(find.text('Kommunikation'), findsOneWidget);
      expect(find.text('Team Postfach'), findsOneWidget);
      expect(find.text('team@example.com'), findsOneWidget);
      expect(find.text('Postfach verbinden'), findsOneWidget);
      expect(find.text('Kanal verbinden'), findsNothing);
    },
  );

  testWidgets(
    'lokale Variante ohne Postfach: der Dialog beginnt bei den Anbietern',
    (tester) async {
      final repository = await _pump(tester, messaging: false);

      await tester.tap(find.text('Postfach verbinden'));
      await tester.pumpAndSettle();

      expect(find.text('Anbieter wählen'), findsOneWidget);
      expect(find.text('Microsoft Outlook'), findsOneWidget);
      expect(find.text('WhatsApp'), findsNothing);

      await tester.tap(find.text('Microsoft Outlook'));
      await tester.pumpAndSettle();

      expect(repository.connections, 1);
    },
  );

  testWidgets(
    'lokale Variante mit Postfach: der Dialog listet die Postfächer und führt über den letzten Eintrag zu den Anbietern',
    (tester) async {
      final repository = await _pump(
        tester,
        messaging: false,
        channels: [_mailbox()],
      );

      await tester.tap(find.text('Postfach verbinden'));
      await tester.pumpAndSettle();

      expect(find.text('Postfächer'), findsOneWidget);
      expect(find.text('Weiteres Postfach verbinden'), findsOneWidget);
      expect(find.text('Anbieter wählen'), findsNothing);

      await tester.tap(find.text('Weiteres Postfach verbinden'));
      await tester.pumpAndSettle();
      expect(find.text('Anbieter wählen'), findsOneWidget);
      expect(repository.connections, 0);

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      expect(find.text('Postfächer'), findsOneWidget);
    },
  );

  testWidgets(
    'lokale Variante: im Dialog lässt sich ein abgelaufenes Postfach neu verbinden',
    (tester) async {
      final repository = await _pump(
        tester,
        messaging: false,
        channels: [
          _mailbox(status: CommunicationChannelStatus.reauthorizationRequired),
        ],
      );

      await tester.tap(find.text('Postfach verbinden'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Neu verbinden').last);
      await tester.pumpAndSettle();

      expect(repository.connections, 1);
    },
  );

  testWidgets(
    'lokale Variante: ein Postfach mit abgelaufener Anmeldung lässt sich neu verbinden',
    (tester) async {
      final repository = await _pump(
        tester,
        messaging: false,
        channels: [
          _mailbox(status: CommunicationChannelStatus.reauthorizationRequired),
        ],
      );

      await tester.tap(find.byTooltip('Postfach neu verbinden'));
      await tester.pumpAndSettle();

      expect(repository.connections, 1);
    },
  );

  testWidgets('Cloud: Kanal verbinden fragt zuerst nach der Art des Kanals', (
    tester,
  ) async {
    final repository = await _pump(tester, messaging: true);

    expect(find.text('Kanal verbinden'), findsOneWidget);
    await tester.tap(find.text('Kanal verbinden'));
    await tester.pumpAndSettle();

    expect(find.text('E-Mail mit Microsoft Outlook'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(repository.connections, 0);
  });

  testWidgets('ohne Postfächer erscheint der Leerzustand', (tester) async {
    await _pump(tester, messaging: false);

    expect(find.text('Team Postfach'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('die Karte nennt Anbieter, Richtung und Status', (tester) async {
    await _pump(tester, messaging: false, channels: [_mailbox()]);

    expect(
      find.text('Microsoft Outlook · Empfangen und senden'),
      findsOneWidget,
    );
    expect(find.text('Aktiv'), findsOneWidget);
  });

  testWidgets('Leerzustand bietet die Verbindung selbst an', (tester) async {
    await _pump(tester, messaging: false);

    expect(find.text('Noch keine Verbindungen'), findsOneWidget);
    expect(find.text('Postfach verbinden'), findsOneWidget);
  });

  testWidgets('Fehler ohne Daten zeigt Erneut versuchen', (tester) async {
    await _pump(tester, messaging: false, failing: true);

    expect(find.text('Postfächer nicht erreichbar'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
