import '../entities/media_input_submission.dart';
import '../repositories/task_run_media_input_repository.dart';

class UploadTaskRunMediaInput {
  const UploadTaskRunMediaInput(this._repository);

  final TaskRunMediaInputRepository _repository;

  Future<String> call(MediaInputSubmission submission) {
    return _repository.upload(submission);
  }
}
