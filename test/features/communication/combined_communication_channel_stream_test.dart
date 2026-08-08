import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/infrastructure/datasources/combined_communication_channel_stream.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

void main() {
  test('vereint direkte und connector-basierte Kanäle', () async {
    final directController = StreamController<List<CommunicationChannel>>();
    final connectorController = StreamController<List<CommunicationChannel>>();
    final emissions = <List<CommunicationChannel>>[];
    final subscription = combineCommunicationChannelStreams(
      directChannels: directController.stream,
      connectorChannels: connectorController.stream,
    ).listen(emissions.add);

    directController.add(const [_smsChannel]);
    await Future<void>.delayed(Duration.zero);
    connectorController.add(const [_emailChannel]);
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last, containsAll([_emailChannel, _smsChannel]));

    await subscription.cancel();
    await directController.close();
    await connectorController.close();
  });
}

const _smsChannel = CommunicationChannel(
  id: 'sms.1',
  teamId: TeamId('team.1'),
  createdByUid: 'user.1',
  provider: CommunicationProvider.twilio,
  kind: CommunicationChannelKind.sms,
  label: 'SMS',
  address: '+491111111111',
  status: CommunicationChannelStatus.active,
  capabilities: ChannelCapabilities(inbound: true, outbound: true),
);

const _emailChannel = CommunicationChannel(
  id: 'mail.1',
  teamId: TeamId('team.1'),
  createdByUid: 'user.1',
  provider: CommunicationProvider.microsoftGraph,
  kind: CommunicationChannelKind.email,
  label: 'Outlook',
  address: 'team@novooa.de',
  status: CommunicationChannelStatus.active,
  capabilities: ChannelCapabilities(inbound: true, outbound: true),
  connectorId: 'mail.1',
);
