import '../entities/media_input_submission.dart';

abstract interface class TaskRunMediaInputRepository {
  Future<String> upload(MediaInputSubmission submission);
}
