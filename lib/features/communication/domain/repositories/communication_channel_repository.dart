import '../entities/communication_channel.dart';

abstract interface class CommunicationChannelRepository {
  Stream<List<CommunicationChannel>> watchChannels();

  Future<String> beginMicrosoftConnection();
}
