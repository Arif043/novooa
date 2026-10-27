import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum DataFileFormat {
  csv,
  json;

  String get extension => name;

  /// Format nach der Dateiendung; `null`, wenn die Datei weder CSV noch JSON ist.
  static DataFileFormat? ofFileName(String fileName) {
    final lower = fileName.toLowerCase();
    for (final format in values) {
      if (lower.endsWith('.${format.extension}')) return format;
    }
    return null;
  }
}

/// Eine Datei für Import oder Export samt Inhalt.
class DataFile extends Equatable {
  const DataFile({required this.name, required this.bytes});

  /// Größte Importdatei; die Runtime prüft dieselbe Grenze.
  static const maximumImportBytes = 5 * 1024 * 1024;

  final String name;
  final Uint8List bytes;

  DataFileFormat? get format => DataFileFormat.ofFileName(name);

  bool get isTooLargeForImport => bytes.length > maximumImportBytes;

  @override
  List<Object> get props => [name, bytes];
}
