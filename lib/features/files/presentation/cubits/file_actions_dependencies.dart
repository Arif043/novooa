import '../../domain/usecases/copy_team_file.dart';
import '../../domain/usecases/create_file_version.dart';
import '../../domain/usecases/delete_team_file.dart';
import '../../domain/usecases/move_team_file.dart';
import '../../domain/usecases/rename_team_file.dart';
import '../../domain/usecases/restore_file_version.dart';
import '../../domain/usecases/save_file_version_to_device.dart';

/// Die Use Cases hinter den Aktionen der Detailseite, gebündelt, damit der
/// Cubit nicht acht Konstruktorparameter braucht.
class FileActionsDependencies {
  const FileActionsDependencies({
    required this.rename,
    required this.move,
    required this.copy,
    required this.delete,
    required this.restore,
    required this.saveToDevice,
    required this.createVersion,
  });

  final RenameTeamFile rename;
  final MoveTeamFile move;
  final CopyTeamFile copy;
  final DeleteTeamFile delete;
  final RestoreFileVersion restore;
  final SaveFileVersionToDevice saveToDevice;
  final CreateFileVersion createVersion;
}
