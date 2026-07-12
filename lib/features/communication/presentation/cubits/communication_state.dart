import '../../domain/entities/communication_channel.dart';

enum CommunicationLoadStatus { loading, ready, failure }

class CommunicationState {
  const CommunicationState({
    this.status = CommunicationLoadStatus.loading,
    this.channels = const [],
    this.isCreating = false,
    this.message,
  });

  final CommunicationLoadStatus status;
  final List<CommunicationChannel> channels;
  final bool isCreating;
  final String? message;

  CommunicationState copyWith({
    CommunicationLoadStatus? status,
    List<CommunicationChannel>? channels,
    bool? isCreating,
    String? message,
  }) {
    return CommunicationState(
      status: status ?? this.status,
      channels: channels ?? this.channels,
      isCreating: isCreating ?? this.isCreating,
      message: message,
    );
  }
}
