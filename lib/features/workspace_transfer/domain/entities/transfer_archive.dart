import 'dart:typed_data';

/// Eine Export-Datei (ZIP) samt vorgeschlagenem Dateinamen.
class TransferArchive {
  const TransferArchive({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;

  static String fileNameFor(DateTime exportedAt) {
    final date = exportedAt.toIso8601String().substring(0, 10);
    return 'novooa-export-$date.zip';
  }
}
