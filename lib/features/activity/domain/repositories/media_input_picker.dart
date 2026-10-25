import '../entities/media_input_submission.dart';
import '../entities/task_run_media_input.dart';

abstract interface class MediaInputPicker {
  /// Nimmt ein Bild aus [source] auf; `null`, wenn abgebrochen. Den Scan im
  /// Browser übernimmt `DocumentScanPage`, bevor dieser Picker gefragt wird.
  Future<MediaInputSubmission?> pick(TaskRunMediaInputSource source);
}
