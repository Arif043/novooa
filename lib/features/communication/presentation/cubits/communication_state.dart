import '../../domain/entities/communication_channel.dart';

enum CommunicationLoadStatus { loading, ready, failure }

class CommunicationState {
  const CommunicationState({
    this.status = CommunicationLoadStatus.loading,
    this.channels = const [],
    this.isConnecting = false,
    this.message,
  });

  final CommunicationLoadStatus status;
  final List<CommunicationChannel> channels;
  final bool isConnecting;
  final String? message;

  CommunicationState copyWith({
    CommunicationLoadStatus? status,
    List<CommunicationChannel>? channels,
    bool? isConnecting,
    String? message,
  }) {
    return CommunicationState(
      status: status ?? this.status,
      channels: channels ?? this.channels,
      isConnecting: isConnecting ?? this.isConnecting,
      message: message,
    );
  }
}
