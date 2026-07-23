import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/services/markdown_link_extractor.dart';

void main() {
  test('findet Wiki-Links und Markdown-Links zu bekannten Notizen', () {
    final extractor = MarkdownLinkExtractor();
    final links = extractor(
      content: 'Siehe [[Index]] und [Details](details.md).',
      notes: [
        KnowledgeNote(
          id: 'note.index',
          knowledgeBaseId: 'default',
          title: 'Index',
          path: 'index.md',
          content: '',
          outgoingLinks: [],
          updatedAt: _date,
        ),
        KnowledgeNote(
          id: 'note.details',
          knowledgeBaseId: 'default',
          title: 'Details',
          path: 'details.md',
          content: '',
          outgoingLinks: [],
          updatedAt: _date,
        ),
      ],
    );

    expect(links, ['note.index', 'note.details']);
  });
}

final _date = DateTime.fromMillisecondsSinceEpoch(0);
