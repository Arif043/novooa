import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';

enum FilesLoadStatus { loading, ready, failure }

class FilesState {
  const FilesState({
    this.status = FilesLoadStatus.loading,
    this.files = const [],
    this.folders = const [],
    this.currentFolderId,
    this.isUploading = false,
    this.isCreatingFolder = false,
    this.message,
  });

  final FilesLoadStatus status;
  final List<TeamFile> files;
  final List<TeamFolder> folders;
  final String? currentFolderId;
  final bool isUploading;
  final bool isCreatingFolder;
  final String? message;

  List<TeamFile> get visibleFiles {
    return files.where((file) => file.folderId == currentFolderId).toList();
  }

  List<TeamFolder> get visibleFolders {
    return folders
        .where((folder) => folder.parentFolderId == currentFolderId)
        .toList();
  }

  List<TeamFolder> get breadcrumbs {
    final path = <TeamFolder>[];
    var folderId = currentFolderId;
    while (folderId != null) {
      final folder = _folderById(folderId);
      if (folder == null) break;
      path.insert(0, folder);
      folderId = folder.parentFolderId;
    }
    return path;
  }

  FilesState copyWith({
    FilesLoadStatus? status,
    List<TeamFile>? files,
    List<TeamFolder>? folders,
    String? currentFolderId,
    bool clearCurrentFolderId = false,
    bool? isUploading,
    bool? isCreatingFolder,
    String? message,
  }) {
    return FilesState(
      status: status ?? this.status,
      files: files ?? this.files,
      folders: folders ?? this.folders,
      currentFolderId: clearCurrentFolderId
          ? null
          : currentFolderId ?? this.currentFolderId,
      isUploading: isUploading ?? this.isUploading,
      isCreatingFolder: isCreatingFolder ?? this.isCreatingFolder,
      message: message,
    );
  }

  TeamFolder? _folderById(String id) {
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }
}
