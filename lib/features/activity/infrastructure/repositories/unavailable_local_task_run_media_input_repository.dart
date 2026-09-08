import '../../domain/entities/media_input_submission.dart';
import '../../domain/repositories/task_run_media_input_repository.dart';

class UnavailableLocalTaskRunMediaInputRepository
    implements TaskRunMediaInputRepository {
  @override
  Future<String> upload(MediaInputSubmission submission) {
    throw UnsupportedError(
      'Bildeingaben werden in der lokalen Runtime noch nicht unterstützt.',
    );
  }
}
