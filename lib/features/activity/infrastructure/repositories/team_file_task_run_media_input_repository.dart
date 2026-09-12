import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../files/domain/entities/upload_file_input.dart';
import '../../../files/domain/usecases/upload_team_file.dart';
import '../../../teams/domain/usecases/get_current_team_id.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/repositories/task_run_media_input_repository.dart';

class TeamFileTaskRunMediaInputRepository
    implements TaskRunMediaInputRepository {
  const TeamFileTaskRunMediaInputRepository(
    this._authRepository,
    this._getCurrentTeamId,
    this._uploadTeamFile,
  );

  final AuthRepository _authRepository;
  final GetCurrentTeamId _getCurrentTeamId;
  final UploadTeamFile _uploadTeamFile;

  @override
  Future<String> upload(MediaInputSubmission submission) async {
    final user = _authRepository.currentUser();
    if (user == null) throw StateError('Du musst angemeldet sein.');
    final teamId = await _getCurrentTeamId();
    final fileOrFailure = await _uploadTeamFile(
      teamId: teamId,
      ownerUid: user.id.value,
      folderId: null,
      input: UploadFileInput(
        name: submission.name,
        bytes: submission.bytes,
        sizeBytes: submission.sizeBytes,
        contentType: submission.contentType,
      ),
    );
    return fileOrFailure.when(
      (file) => file.id,
      (failure) => throw StateError(failure.message),
    );
  }
}
