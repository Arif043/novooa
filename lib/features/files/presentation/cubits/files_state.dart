import '../../domain/entities/team_file.dart';

enum FilesLoadStatus { loading, ready, failure }

class FilesState {
  const FilesState({
    this.status = FilesLoadStatus.loading,
    this.files = const [],
    this.isUploading = false,
    this.message,
  });

  final FilesLoadStatus status;
  final List<TeamFile> files;
  final bool isUploading;
  final String? message;

  FilesState copyWith({
    FilesLoadStatus? status,
    List<TeamFile>? files,
    bool? isUploading,
    String? message,
  }) {
    return FilesState(
      status: status ?? this.status,
      files: files ?? this.files,
      isUploading: isUploading ?? this.isUploading,
      message: message,
    );
  }
}
