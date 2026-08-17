import '../entities/media_input_submission.dart';
import '../entities/task_run_media_input.dart';

abstract interface class MediaInputPicker {
  Future<MediaInputSubmission?> pick(TaskRunMediaInputSource source);
}
