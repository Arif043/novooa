import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/presentation/widgets/communication_channel_grid.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

CommunicationChannel _channel({
  required CommunicationChannelStatus status,
  String? connectorId = 'connector-1',
  String id = 'channel-1',
  String label = 'Team-Postfach',
}) {
  return CommunicationChannel(
    id: id,
    teamId: const TeamId('team'),
    createdByUid: 'user',
    provider: CommunicationProvider.microsoftGraph,
    kind: CommunicationChannelKind.email,
    label: label,
    address: 'team@example.com',
    status: status,
    capabilities: const ChannelCapabilities(inbound: true, outbound: true),
    connectorId: connectorId,
  );
}

Widget _host(
  List<CommunicationChannel> channels,
  ValueChanged<CommunicationChannel> onReconnect,
) {
  return MaterialApp(
    home: Scaffold(
      body: CommunicationChannelGrid(
        channels: channels,
        onReconnect: onReconnect,
      ),
    ),
  );
}

void main() {
  test(
    'nur ein Postfach mit abgelaufener Anmeldung braucht das erneute Verbinden',
    () {
      expect(
        _channel(
          status: CommunicationChannelStatus.reauthorizationRequired,
        ).needsReconnection,
        isTrue,
      );
      expect(
        _channel(status: CommunicationChannelStatus.active).needsReconnection,
        isFalse,
      );
      expect(
        _channel(
          status: CommunicationChannelStatus.reauthorizationRequired,
          connectorId: null,
        ).needsReconnection,
        isFalse,
        reason: 'WhatsApp und SMS haben keinen Connector',
      );
    },
  );

  testWidgets(
    'ein Postfach mit abgelaufener Anmeldung bietet Neu verbinden an',
    (tester) async {
      CommunicationChannel? reconnected;
      final broken = _channel(
        status: CommunicationChannelStatus.reauthorizationRequired,
      );
      await tester.pumpWidget(
        _host([broken], (channel) => reconnected = channel),
      );

      expect(find.text('Erneute Anmeldung erforderlich'), findsOneWidget);
      expect(find.textContaining('Verbinde das Postfach neu'), findsOneWidget);
      await tester.tap(find.byTooltip('Postfach neu verbinden'));

      expect(reconnected, broken);
    },
  );

  testWidgets('ein aktives Postfach zeigt keine Aktion zum Neu verbinden', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([_channel(status: CommunicationChannelStatus.active)], (_) {}),
    );

    expect(find.byTooltip('Postfach neu verbinden'), findsNothing);
    expect(find.textContaining('Verbinde das Postfach neu'), findsNothing);
  });
}
