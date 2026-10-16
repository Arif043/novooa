import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _markdownLink = RegExp(r'\]\(([^)\s]+)\)');
final _fencedBlock = RegExp(r'```.*?```', dotAll: true);
final _inlineCode = RegExp(r'`[^`\n]*`');

List<File> _markdownFilesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.md'))
    .toList();

String _proseOf(File file) => file
    .readAsStringSync()
    .replaceAll(_fencedBlock, '')
    .replaceAll(_inlineCode, '');

Iterable<String> _relativeTargetsIn(File file) => _markdownLink
    .allMatches(_proseOf(file))
    .map((match) => match.group(1)!.split('#').first)
    .where((target) => target.isNotEmpty && !target.contains(':'));

String _resolve(File file, String target) =>
    Uri.file(file.path).resolve(target).toFilePath();

bool _exists(String path) =>
    File(path).existsSync() || Directory(path).existsSync();

void main() {
  final docs = [..._markdownFilesIn('docs'), File('AGENTS.md')];
  final notes = _markdownFilesIn('docs/notes');
  final indexes = _markdownFilesIn('docs/index');

  test('Alle relativen Links in den Docs zeigen auf vorhandene Dateien', () {
    final broken = [
      for (final file in docs)
        for (final target in _relativeTargetsIn(file))
          if (!_exists(_resolve(file, target))) '${file.path} → $target',
    ];
    expect(broken, isEmpty);
  });

  test('Jede Notiz hat Titel, Kernaussage und „Gehört zu“', () {
    for (final note in notes) {
      final lines = note.readAsLinesSync();
      expect(lines.first, startsWith('# '), reason: note.path);
      expect(lines, contains(startsWith('> ')), reason: note.path);
      expect(lines, contains(startsWith('Gehört zu: [')), reason: note.path);
      expect(lines.length, lessThanOrEqualTo(200), reason: note.path);
    }
  });

  test('Jede Notiz steht in mindestens einem Inhaltsverzeichnis', () {
    final listed = {
      for (final index in indexes)
        for (final target in _relativeTargetsIn(index)) _resolve(index, target),
    };
    final orphans = notes
        .map((note) => Uri.file(note.path).toFilePath())
        .where((path) => !listed.contains(path));
    expect(orphans, isEmpty);
  });
}
