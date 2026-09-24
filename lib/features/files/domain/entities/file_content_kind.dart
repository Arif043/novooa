/// The category of viewer a [TeamFile]'s content should be rendered with.
///
/// Pure Dart, zero framework dependencies: classification of a MIME type is
/// a business rule, not a UI concern.
enum FileContentKind { text, image, pdf, spreadsheet, unsupported }

/// Maps a raw MIME content type to a [FileContentKind].
///
/// Kept as a small strategy so new kinds (e.g. pdf, audio) can be added by
/// extending this classifier without touching the presentation layer (OCP).
class FileContentKindClassifier {
  const FileContentKindClassifier();

  /// [fileName] is an optional fallback for files whose stored `contentType`
  /// is a generic placeholder like `application/octet-stream` — browsers and
  /// `file_picker` don't reliably know less common MIME types (e.g. `.ods`)
  /// at upload time, and files uploaded before such a type was supported
  /// keep their old, generic content type forever. The extension fallback
  /// lets those files still be classified correctly without re-uploading.
  FileContentKind classify(String contentType, {String? fileName}) {
    if (_isText(contentType)) return FileContentKind.text;
    if (_isImage(contentType)) return FileContentKind.image;
    if (_isPdf(contentType)) return FileContentKind.pdf;
    if (_isSpreadsheet(contentType)) return FileContentKind.spreadsheet;
    if (_isGenericBinary(contentType) && _hasOdsExtension(fileName)) {
      return FileContentKind.spreadsheet;
    }
    return FileContentKind.unsupported;
  }

  bool _isText(String contentType) =>
      contentType.startsWith('text/') || contentType == 'application/json';

  bool _isImage(String contentType) => contentType.startsWith('image/');

  bool _isPdf(String contentType) => contentType == 'application/pdf';

  bool _isSpreadsheet(String contentType) =>
      contentType == 'application/vnd.oasis.opendocument.spreadsheet';

  bool _isGenericBinary(String contentType) =>
      contentType == 'application/octet-stream' || contentType.isEmpty;

  bool _hasOdsExtension(String? fileName) =>
      fileName?.toLowerCase().endsWith('.ods') ?? false;
}
