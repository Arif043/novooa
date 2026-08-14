class WikiLink {
  const WikiLink({required this.target, required this.label});

  final String target;
  final String label;
}

class WikiLinkParser {
  const WikiLinkParser();

  List<WikiLink> call(String content) {
    return _pattern
        .allMatches(content)
        .map(_linkFrom)
        .whereType<WikiLink>()
        .toList(growable: false);
  }

  WikiLink? _linkFrom(RegExpMatch match) {
    final target = _targetFrom(match.group(1));
    if (target.isEmpty) return null;
    final label = match.group(2)?.trim();
    final visibleLabel = label == null || label.isEmpty ? target : label;
    return WikiLink(target: target, label: visibleLabel);
  }

  String _targetFrom(String? value) {
    final target = value?.trim() ?? '';
    return target.split(RegExp(r'[#^]')).first.trim();
  }
}

final _pattern = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');
