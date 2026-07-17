import 'communication_channel.dart';

class CreateCommunicationChannelInput {
  const CreateCommunicationChannelInput({
    required this.provider,
    required this.kind,
    required this.label,
    required this.address,
    required this.capabilities,
  });

  final CommunicationProvider provider;
  final CommunicationChannelKind kind;
  final String label;
  final String address;
  final ChannelCapabilities capabilities;

  bool get isValid {
    return label.trim().isNotEmpty &&
        address.trim().isNotEmpty &&
        (capabilities.inbound || capabilities.outbound);
  }
}
