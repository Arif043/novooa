import 'dart:typed_data';

class ScannedDocument {
  const ScannedDocument({
    required this.bytes,
    this.name = 'scan.jpg',
    this.contentType = 'image/jpeg',
  });

  final Uint8List bytes;
  final String name;
  final String contentType;
}
