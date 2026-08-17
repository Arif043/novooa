import 'package:image_picker/image_picker.dart';

import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run_media_input.dart';
import '../../domain/repositories/media_input_picker.dart';

class ImagePickerMediaInputPicker implements MediaInputPicker {
  const ImagePickerMediaInputPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<MediaInputSubmission?> pick(TaskRunMediaInputSource source) async {
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
    return source == TaskRunMediaInputSource.camera
        ? ImageSource.camera
        : ImageSource.gallery;
  }

  String _nameFor(XFile image, TaskRunMediaInputSource source) {
    if (image.name.trim().isNotEmpty) return image.name;
    final prefix = source == TaskRunMediaInputSource.camera
        ? 'aufnahme'
        : 'bild';
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
