import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/knowledge_note.dart';
import '../../domain/services/knowledge_note_resolver.dart';
import 'knowledge_wiki_link_syntax.dart';

typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

/// Entscheidet, was ein angetippter Link in der Lesen-Ansicht tut: Notizen
/// öffnen sich in der Wissensbasis, Web- und Mail-Adressen extern.
class KnowledgeMarkdownLinkHandler {
  const KnowledgeMarkdownLinkHandler({
    required this.notes,
    required this.onNoteSelected,
    this.openExternal = launchExternalLink,
    this.resolver = const KnowledgeNoteResolver(),
  });

  final List<KnowledgeNote> notes;
  final ValueChanged<String> onNoteSelected;
  final ExternalLinkOpener openExternal;
  final KnowledgeNoteResolver resolver;

  void call(String text, String? href, String title) {
    if (href == null || href.trim().isEmpty) return;
    final noteId = _noteIdFor(href);
    if (noteId != null) {
      onNoteSelected(noteId);
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri != null && _externalSchemes.contains(uri.scheme)) {
      openExternal(uri);
    }
  }

  String? _noteIdFor(String href) {
    const prefix = '$knowledgeNoteLinkScheme:';
    if (href.startsWith(prefix)) return href.substring(prefix.length);
    return resolver.resolve(_decoded(href), notes)?.id;
  }

  String _decoded(String href) {
    try {
      return Uri.decodeComponent(href);
    } on ArgumentError {
      return href;
    }
  }
}

const _externalSchemes = {'http', 'https', 'mailto'};

/// Öffnet eine Web- oder Mail-Adresse außerhalb der App (Browser, Mailprogramm).
Future<bool> launchExternalLink(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
