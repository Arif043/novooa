import '../entities/create_communication_channel_input.dart';
import '../repositories/communication_channel_repository.dart';

class CreateCommunicationChannel {
  const CreateCommunicationChannel(this._repository);

  final CommunicationChannelRepository _repository;

  Future<void> call(CreateCommunicationChannelInput input) {
    return _repository.createChannel(input);
  }
}
