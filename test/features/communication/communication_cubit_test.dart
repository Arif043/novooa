import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/communication/domain/entities/communication_channel.dart';
import 'package:syscat2/features/communication/domain/entities/create_communication_channel_input.dart';
import 'package:syscat2/features/communication/domain/entities/send_channel_message_input.dart';
import 'package:syscat2/features/communication/domain/repositories/communication_channel_repository.dart';
import 'package:syscat2/features/communication/domain/usecases/create_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/delete_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/dispatch_fake_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/send_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/watch_communication_channels.dart';
import 'package:syscat2/features/communication/presentation/cubits/communication_cubit.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

void main() {
  test('send uebergibt Nachricht an Repository', () async {
    final repository = _FakeCommunicationRepository();
    final cubit = _cubit(repository);

    await cubit.send(channel: _channel, to: '+491234567890', body: 'Hallo');

    expect(repository.sentMessages.single.to, '+491234567890');
    expect(repository.sentMessages.single.body, 'Hallo');
    expect(repository.sentMessages.single.channelId, _channel.id);
    expect(cubit.state.message, 'Nachricht gesendet.');

    await cubit.close();
  });

  test('send meldet Fehler bei Repository-Fehler', () async {
    final repository = _FakeCommunicationRepository(shouldFailSend: true);
    final cubit = _cubit(repository);

    await cubit.send(channel: _channel, to: '+491234567890', body: 'Hallo');

    expect(cubit.state.message, 'Nachricht konnte nicht gesendet werden.');

    await cubit.close();
  });
}

CommunicationCubit _cubit(_FakeCommunicationRepository repository) {
  return CommunicationCubit(
    WatchCommunicationChannels(repository),
    CreateCommunicationChannel(repository),
    DeleteCommunicationChannel(repository),
    DispatchFakeChannelMessage(repository),
    SendChannelMessage(repository),
  );
}

const _channel = CommunicationChannel(
  id: 'channel.1',
  teamId: TeamId('team.1'),
  createdByUid: 'user.1',
  provider: CommunicationProvider.twilio,
  kind: CommunicationChannelKind.sms,
  label: 'SMS',
  address: '+491111111111',
  status: CommunicationChannelStatus.active,
  capabilities: ChannelCapabilities(inbound: true, outbound: true),
);

class _FakeCommunicationRepository implements CommunicationChannelRepository {
  _FakeCommunicationRepository({this.shouldFailSend = false});

  final bool shouldFailSend;
  final List<SendChannelMessageInput> sentMessages = [];

  @override
  Stream<List<CommunicationChannel>> watchChannels() {
    return Stream.value(const [_channel]);
  }

  @override
  Future<void> createChannel(CreateCommunicationChannelInput input) async {}

  @override
  Future<void> deleteChannel(String channelId) async {}

  @override
  Future<void> dispatchFakeMessage(String channelId) async {}

  @override
  Future<void> sendMessage(SendChannelMessageInput input) async {
    if (shouldFailSend) throw StateError('failed');
    sentMessages.add(input);
  }
}
