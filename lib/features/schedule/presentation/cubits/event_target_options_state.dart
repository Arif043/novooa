import '../../../communication/domain/entities/communication_channel.dart';
import '../../../files/domain/entities/team_file.dart';
import '../../../files/domain/entities/team_folder.dart';

enum EventTargetOptionsStatus { loading, ready, failure }

class EventTargetOptionsState {
  const EventTargetOptionsState({
    this.status = EventTargetOptionsStatus.loading,
    this.files = const [],
    this.folders = const [],
    this.channels = const [],
  });

  final EventTargetOptionsStatus status;
  final List<TeamFile> files;
  final List<TeamFolder> folders;
  final List<CommunicationChannel> channels;

  EventTargetOptionsState copyWith({
    EventTargetOptionsStatus? status,
    List<TeamFile>? files,
    List<TeamFolder>? folders,
    List<CommunicationChannel>? channels,
  }) {
    return EventTargetOptionsState(
      status: status ?? this.status,
      files: files ?? this.files,
      folders: folders ?? this.folders,
      channels: channels ?? this.channels,
    );
  }
}
