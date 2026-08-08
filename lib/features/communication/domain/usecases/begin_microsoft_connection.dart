import '../repositories/communication_channel_repository.dart';

class BeginMicrosoftConnection {
  const BeginMicrosoftConnection(this._repository);

  final CommunicationChannelRepository _repository;

  Future<String> call() => _repository.beginMicrosoftConnection();
}
