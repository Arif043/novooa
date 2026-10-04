import '../entities/media_input_submission.dart';
import '../entities/task_run_media_input.dart';

abstract interface class MediaInputPicker {
  /// [documentScanEnabled] wirkt nur bei [TaskRunMediaInputSource.camera] und
  /// nur, wenn die Plattform einen nativen Dokumentenscanner hat (Android, iOS)
  /// — siehe `ImagePickerMediaInputPicker`. Im Browser scannt stattdessen
  /// `DocumentScanPage`, bevor dieser Picker gefragt wird.
  Future<MediaInputSubmission?> pick(
    TaskRunMediaInputSource source, {
    bool documentScanEnabled = false,
  });
}
