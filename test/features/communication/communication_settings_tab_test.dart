import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/domain/repositories/communication_channel_repository.dart';
import 'package:syscat2/features/communication/domain/usecases/begin_microsoft_connection.dart';
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

Future<_FakeRepository> _pump(
  WidgetTester tester, {
  List<CommunicationChannel> channels = const [],
  bool failing = false,
}) async {
  final repository = _FakeRepository(channels, failing: failing);
  serviceLocator.registerFactory(
    () => CommunicationCubit(
      WatchCommunicationChannels(repository),
      BeginMicrosoftConnection(repository),
    ),
  );
  addTearDown(() => serviceLocator.unregister<CommunicationCubit>());
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: CommunicationSettingsTab())),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('zeigt die Postfächer und bietet nur Postfach verbinden an', (
    tester,
  ) async {
    await _pump(tester, channels: [_mailbox()]);

    expect(find.text('Kommunikation'), findsOneWidget);
    expect(find.text('Team Postfach'), findsOneWidget);
    expect(find.text('team@example.com'), findsOneWidget);
    expect(find.text('Postfach verbinden'), findsOneWidget);
    expect(find.text('Kanal verbinden'), findsNothing);
  });

  testWidgets('ohne Postfach: der Dialog beginnt bei den Anbietern', (
    tester,
  ) async {
    final repository = await _pump(tester);

    await tester.tap(find.text('Postfach verbinden'));
    await tester.pumpAndSettle();

    expect(find.text('Anbieter wählen'), findsOneWidget);
    expect(find.text('Microsoft Outlook'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing);

    await tester.tap(find.text('Microsoft Outlook'));
    await tester.pumpAndSettle();

    expect(repository.connections, 1);
  });

  testWidgets(
    'mit Postfach: der Dialog listet die Postfächer und führt über den letzten Eintrag zu den Anbietern',
    (tester) async {
      final repository = await _pump(tester, channels: [_mailbox()]);

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

  testWidgets('im Dialog lässt sich ein abgelaufenes Postfach neu verbinden', (
    tester,
  ) async {
    final repository = await _pump(
      tester,
      channels: [
        _mailbox(status: CommunicationChannelStatus.reauthorizationRequired),
      ],
    );

    await tester.tap(find.text('Postfach verbinden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Neu verbinden').last);
    await tester.pumpAndSettle();

    expect(repository.connections, 1);
  });

  testWidgets(
    'ein Postfach mit abgelaufener Anmeldung lässt sich neu verbinden',
    (tester) async {
      final repository = await _pump(
        tester,
        channels: [
          _mailbox(status: CommunicationChannelStatus.reauthorizationRequired),
        ],
      );

      await tester.tap(find.byTooltip('Postfach neu verbinden'));
      await tester.pumpAndSettle();

      expect(repository.connections, 1);
    },
  );

  testWidgets('ohne Postfächer erscheint der Leerzustand', (tester) async {
    await _pump(tester);

    expect(find.text('Team Postfach'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('die Karte nennt Anbieter, Richtung und Status', (tester) async {
    await _pump(tester, channels: [_mailbox()]);

    expect(
      find.text('Microsoft Outlook · Empfangen und senden'),
      findsOneWidget,
    );
    expect(find.text('Aktiv'), findsOneWidget);
  });

  testWidgets('Leerzustand bietet die Verbindung selbst an', (tester) async {
    await _pump(tester);

    expect(find.text('Noch keine Verbindungen'), findsOneWidget);
    expect(find.text('Postfach verbinden'), findsOneWidget);
  });

  testWidgets('Fehler ohne Daten zeigt Erneut versuchen', (tester) async {
    await _pump(tester, failing: true);

    expect(find.text('Postfächer nicht erreichbar'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
