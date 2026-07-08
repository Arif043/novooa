import 'dart:typed_data';

class UploadFileInput {
  const UploadFileInput({
    required this.name,
    required this.bytes,
    required this.sizeBytes,
    this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final int sizeBytes;
  final String? contentType;
}
