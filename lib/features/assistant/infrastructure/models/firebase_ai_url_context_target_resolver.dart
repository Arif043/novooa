class FirebaseAiUrlContextTargetResolver {
  const FirebaseAiUrlContextTargetResolver();

  static final _urlPattern = RegExp(
    r'(?:https?://|www\.)?'
    r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?'
    r'(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+'
    r'(?::\d{1,5})?(?:/[^\s<>()\[\]{}]*)?',
    caseSensitive: false,
  );

  List<Uri> urlsIn(String text) {
    final urls = <Uri>{};
    for (final match in _urlPattern.allMatches(text)) {
      if (_startsInsideEmail(text, match.start)) continue;
      final uri = _uriFor(match.group(0)!);
      if (uri != null) urls.add(uri);
    }
    return urls.toList(growable: false);
  }

  Uri? _uriFor(String candidate) {
    final url = _trimPunctuation(candidate);
    final normalized = _hasScheme(url) ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasAuthority) return null;
    return uri;
  }

  String _trimPunctuation(String value) {
    return value.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
  }

  bool _startsInsideEmail(String text, int start) {
    return start > 0 && text[start - 1] == '@';
  }

  bool _hasScheme(String url) {
    final lowerCaseUrl = url.toLowerCase();
    return lowerCaseUrl.startsWith('http://') ||
        lowerCaseUrl.startsWith('https://');
  }
}
