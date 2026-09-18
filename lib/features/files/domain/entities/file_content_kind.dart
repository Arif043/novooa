/// The category of viewer a [TeamFile]'s content should be rendered with.
///
/// Pure Dart, zero framework dependencies: classification of a MIME type is
/// a business rule, not a UI concern.
enum FileContentKind { text, image, pdf, unsupported }

/// Maps a raw MIME content type to a [FileContentKind].
///
/// Kept as a small strategy so new kinds (e.g. pdf, audio) can be added by
/// extending this classifier without touching the presentation layer (OCP).
class FileContentKindClassifier {
  const FileContentKindClassifier();

  FileContentKind classify(String contentType) {
    if (_isText(contentType)) return FileContentKind.text;
    if (_isImage(contentType)) return FileContentKind.image;
    if (_isPdf(contentType)) return FileContentKind.pdf;
    return FileContentKind.unsupported;
  }

  bool _isText(String contentType) =>
      contentType.startsWith('text/') || contentType == 'application/json';

  bool _isImage(String contentType) => contentType.startsWith('image/');

  bool _isPdf(String contentType) => contentType == 'application/pdf';
}
