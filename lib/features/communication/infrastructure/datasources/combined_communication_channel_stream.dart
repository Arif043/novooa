import 'dart:async';

import '../../domain/entities/communication_channel.dart';

Stream<List<CommunicationChannel>> combineCommunicationChannelStreams({
  required Stream<List<CommunicationChannel>> directChannels,
  required Stream<List<CommunicationChannel>> connectorChannels,
}) {
  return Stream.multi((controller) {
    var direct = const <CommunicationChannel>[];
    var connectors = const <CommunicationChannel>[];
    void publish() => controller.add([...connectors, ...direct]);
    final subscriptions = [
      directChannels.listen((channels) {
        direct = channels;
        publish();
      }, onError: controller.addError),
      connectorChannels.listen((channels) {
        connectors = channels;
        publish();
      }, onError: controller.addError),
    ];
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
  });
}
