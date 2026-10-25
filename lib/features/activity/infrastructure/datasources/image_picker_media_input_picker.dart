import 'dart:async';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/platform/document_scan_support.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run_media_input.dart';
import '../../domain/repositories/media_input_picker.dart';

class ImagePickerMediaInputPicker implements MediaInputPicker {
  const ImagePickerMediaInputPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<MediaInputSubmission?> pick(TaskRunMediaInputSource source) {
    if (source == TaskRunMediaInputSource.documentScan &&
        nativeDocumentScanSupportedOnThisPlatform()) {
      return _pickWithDocumentScanner();
    }
    return _pickWithImagePicker(source);
  }

  Future<MediaInputSubmission?> _pickWithDocumentScanner() async {
    final paths = await CunningDocumentScanner.getPictures(
      noOfPages: 1,
      scannerSource: ScannerSource.camera,
    );
    // cleanCache läuft bewusst nach dem Lesen und ohne den Rückgabewert
    // abzuwarten: Ein Fehlschlag beim Aufräumen des plugin-eigenen
    // Zwischenspeichers darf die eigentliche Aufnahme nicht verhindern.
    unawaited(CunningDocumentScanner.cleanCache());
    final path = paths?.firstOrNull;
    if (path == null) return null;
    final file = File(path);
    return MediaInputSubmission(
      name: 'scan.jpg',
      bytes: await file.readAsBytes(),
      contentType: 'image/jpeg',
    );
  }

  Future<MediaInputSubmission?> _pickWithImagePicker(
    TaskRunMediaInputSource source,
  ) async {
    final image = await _picker.pickImage(source: _sourceFor(source));
    if (image == null) return null;
    final name = _nameFor(image, source);
    return MediaInputSubmission(
      name: name,
      bytes: await image.readAsBytes(),
      contentType: _contentTypeFor(name),
    );
  }

  ImageSource _sourceFor(TaskRunMediaInputSource source) {
    return source == TaskRunMediaInputSource.gallery
        ? ImageSource.gallery
        : ImageSource.camera;
  }

  String _nameFor(XFile image, TaskRunMediaInputSource source) {
    if (image.name.trim().isNotEmpty) return image.name;
    final prefix = source == TaskRunMediaInputSource.gallery
        ? 'bild'
        : 'aufnahme';
    return '$prefix.jpg';
  }

  String _contentTypeFor(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}
