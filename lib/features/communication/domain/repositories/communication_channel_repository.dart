import '../entities/communication_channel.dart';
import '../entities/create_communication_channel_input.dart';

abstract interface class CommunicationChannelRepository {
  Stream<List<CommunicationChannel>> watchChannels();

  Future<void> createChannel(CreateCommunicationChannelInput input);

  Future<void> deleteChannel(String channelId);
}
