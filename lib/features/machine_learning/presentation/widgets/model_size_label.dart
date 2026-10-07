/// Dateigröße eines Modells für die Anzeige, z. B. „12 KB“ oder „84,3 MB“.
String modelSizeLabel(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  final megabytes = (bytes / (1024 * 1024)).toStringAsFixed(1);
  return '${megabytes.replaceAll('.', ',')} MB';
}
