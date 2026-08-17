import 'dart:typed_data';

class MediaInputSubmission {
  const MediaInputSubmission({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;

  int get sizeBytes => bytes.lengthInBytes;
}
