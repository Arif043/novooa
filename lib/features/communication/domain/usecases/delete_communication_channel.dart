import '../repositories/communication_channel_repository.dart';

class DeleteCommunicationChannel {
  const DeleteCommunicationChannel(this._repository);

  final CommunicationChannelRepository _repository;

  Future<void> call(String channelId) {
    return _repository.deleteChannel(channelId);
  }
}
