import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/domain/repositories/communication_channel_repository.dart';
import 'package:syscat2/features/communication/domain/usecases/begin_microsoft_connection.dart';
import 'package:syscat2/features/communication/domain/usecases/watch_communication_channels.dart';
import 'package:syscat2/features/communication/presentation/cubits/communication_cubit.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

void main() {
  test('startet die Microsoft-Anmeldung über den Kanal-Use-Case', () async {
    final repository = _FakeCommunicationRepository();
    final cubit = _cubit(repository);

    final authorizationUrl = await cubit.beginMicrosoftConnection();

    expect(authorizationUrl, 'https://login.microsoftonline.com');
    expect(cubit.state.isConnecting, isFalse);
    await cubit.close();
  });
}

CommunicationCubit _cubit(_FakeCommunicationRepository repository) {
  return CommunicationCubit(
    WatchCommunicationChannels(repository),
    BeginMicrosoftConnection(repository),
  );
}

const _channel = CommunicationChannel(
  id: 'channel.1',
  teamId: TeamId('team.1'),
  createdByUid: 'user.1',
  provider: CommunicationProvider.microsoftGraph,
  kind: CommunicationChannelKind.email,
  label: 'Postfach',
  address: 'team@example.com',
  status: CommunicationChannelStatus.active,
  capabilities: ChannelCapabilities(inbound: true, outbound: true),
);

class _FakeCommunicationRepository implements CommunicationChannelRepository {
  @override
  Stream<List<CommunicationChannel>> watchChannels() {
    return Stream.value(const [_channel]);
  }

  @override
  Future<String> beginMicrosoftConnection() async {
    return 'https://login.microsoftonline.com';
  }
}
