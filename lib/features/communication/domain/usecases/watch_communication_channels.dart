import '../entities/communication_channel.dart';
import '../repositories/communication_channel_repository.dart';

class WatchCommunicationChannels {
  const WatchCommunicationChannels(this._repository);

  final CommunicationChannelRepository _repository;

  Stream<List<CommunicationChannel>> call() {
    return _repository.watchChannels();
  }
}
