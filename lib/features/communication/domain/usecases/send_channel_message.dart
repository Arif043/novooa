import '../entities/send_channel_message_input.dart';
import '../repositories/communication_channel_repository.dart';

class SendChannelMessage {
  const SendChannelMessage(this._repository);

  final CommunicationChannelRepository _repository;

  Future<void> call(SendChannelMessageInput input) {
    return _repository.sendMessage(input);
  }
}
