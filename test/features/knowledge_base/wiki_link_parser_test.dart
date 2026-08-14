import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/services/wiki_link_parser.dart';

void main() {
  const parser = WikiLinkParser();

  test('liest Obsidian-Links mit Alias und Abschnitt', () {
    final links = parser('Siehe [[Projekt#Plan|zum Projekt]] und [[Index]].');

    expect(links.map((link) => link.target), ['Projekt', 'Index']);
    expect(links.map((link) => link.label), ['zum Projekt', 'Index']);
  });
}
