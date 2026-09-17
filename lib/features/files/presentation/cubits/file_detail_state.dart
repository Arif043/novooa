import 'dart:typed_data';

import '../../domain/entities/file_version.dart';

enum FileDetailStatus { loading, ready, failure }

class FileDetailState {
  const FileDetailState({
    this.status = FileDetailStatus.loading,
    this.versions = const [],
    this.selectedVersion,
    this.bytes,
    this.isSaving = false,
    this.message,
  });

  final FileDetailStatus status;
  final List<FileVersion> versions;
  final FileVersion? selectedVersion;
  final Uint8List? bytes;
  final bool isSaving;
  final String? message;

  FileDetailState copyWith({
    FileDetailStatus? status,
    List<FileVersion>? versions,
    FileVersion? selectedVersion,
    bool clearSelectedVersion = false,
    Uint8List? bytes,
    bool clearBytes = false,
    bool? isSaving,
    String? message,
  }) {
    return FileDetailState(
      status: status ?? this.status,
      versions: versions ?? this.versions,
      selectedVersion: clearSelectedVersion
          ? null
          : selectedVersion ?? this.selectedVersion,
      bytes: clearBytes ? null : bytes ?? this.bytes,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}
