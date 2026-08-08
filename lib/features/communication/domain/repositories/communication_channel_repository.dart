import '../entities/communication_channel.dart';
import '../entities/create_communication_channel_input.dart';
import '../entities/send_channel_message_input.dart';

abstract interface class CommunicationChannelRepository {
  Stream<List<CommunicationChannel>> watchChannels();

  Future<String> beginMicrosoftConnection();

  Future<void> createChannel(CreateCommunicationChannelInput input);

  Future<void> deleteChannel(String channelId);

  Future<void> dispatchFakeMessage(String channelId);

  Future<void> sendMessage(SendChannelMessageInput input);
}
