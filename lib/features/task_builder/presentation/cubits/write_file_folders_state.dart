import 'package:syscat2/features/files/domain/entities/team_folder.dart';

enum WriteFileFoldersStatus { loading, ready, failure }

class WriteFileFoldersState {
  const WriteFileFoldersState({
    this.status = WriteFileFoldersStatus.loading,
    this.folders = const [],
    this.isCreating = false,
    this.message,
  });

  final WriteFileFoldersStatus status;
  final List<TeamFolder> folders;
  final bool isCreating;
  final String? message;

  WriteFileFoldersState copyWith({
    WriteFileFoldersStatus? status,
    List<TeamFolder>? folders,
    bool? isCreating,
    String? message,
  }) {
    return WriteFileFoldersState(
      status: status ?? this.status,
      folders: folders ?? this.folders,
      isCreating: isCreating ?? this.isCreating,
      message: message,
    );
  }
}
