import '../../domain/entities/file_version.dart';

enum FileDetailStatus { loading, ready, failure }

class FileDetailState {
  const FileDetailState({
    this.status = FileDetailStatus.loading,
    this.versions = const [],
    this.selectedVersion,
    this.content,
    this.isSaving = false,
    this.message,
  });

  final FileDetailStatus status;
  final List<FileVersion> versions;
  final FileVersion? selectedVersion;
  final String? content;
  final bool isSaving;
  final String? message;

  FileDetailState copyWith({
    FileDetailStatus? status,
    List<FileVersion>? versions,
    FileVersion? selectedVersion,
    bool clearSelectedVersion = false,
    String? content,
    bool clearContent = false,
    bool? isSaving,
    String? message,
  }) {
    return FileDetailState(
      status: status ?? this.status,
      versions: versions ?? this.versions,
      selectedVersion: clearSelectedVersion
          ? null
          : selectedVersion ?? this.selectedVersion,
      content: clearContent ? null : content ?? this.content,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}
