import 'dart:typed_data';

import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';

sealed class FileDetailState {
  const FileDetailState();
}

final class FileDetailLoading extends FileDetailState {
  const FileDetailLoading();
}

final class FileDetailFailure extends FileDetailState {
  const FileDetailFailure();
}

/// Die Datei wurde gelöscht, während die Seite offen war.
final class FileDetailDeleted extends FileDetailState {
  const FileDetailDeleted();
}

final class FileDetailReady extends FileDetailState {
  const FileDetailReady({
    required this.file,
    this.versions = const [],
    this.folders = const [],
    this.versionLimit,
    this.selectedVersionId,
    this.content = const FileContentLoading(),
  });

  final TeamFile file;

  /// Neueste zuerst; leer, solange der Verlauf lädt.
  final List<FileVersion> versions;
  final List<TeamFolder> folders;
  final int? versionLimit;
  final String? selectedVersionId;
  final FileContentState content;

  FileVersion? get selectedVersion {
    return versions.where((v) => v.id == selectedVersionId).firstOrNull;
  }

  bool isCurrent(FileVersion version) => version.id == file.currentVersionId;

  /// Die Person sieht eine ältere Version, nicht den aktuellen Stand.
  bool get isViewingOldVersion {
    final selected = selectedVersion;
    return selected != null && !isCurrent(selected);
  }

  /// Größenänderung einer Version gegenüber ihrer Vorgängerin; `null` bei der ersten.
  int? sizeDeltaOf(FileVersion version) {
    final index = versions.indexWhere((v) => v.id == version.id);
    if (index < 0 || index + 1 >= versions.length) return null;
    return version.sizeBytes - versions[index + 1].sizeBytes;
  }

  FileDetailReady copyWith({
    TeamFile? file,
    List<FileVersion>? versions,
    List<TeamFolder>? folders,
    int? versionLimit,
    String? selectedVersionId,
    FileContentState? content,
  }) {
    return FileDetailReady(
      file: file ?? this.file,
      versions: versions ?? this.versions,
      folders: folders ?? this.folders,
      versionLimit: versionLimit ?? this.versionLimit,
      selectedVersionId: selectedVersionId ?? this.selectedVersionId,
      content: content ?? this.content,
    );
  }
}

sealed class FileContentState {
  const FileContentState();
}

final class FileContentLoading extends FileContentState {
  const FileContentLoading();
}

final class FileContentLoaded extends FileContentState {
  const FileContentLoaded(this.bytes);

  final Uint8List bytes;
}

final class FileContentFailed extends FileContentState {
  const FileContentFailed();
}
