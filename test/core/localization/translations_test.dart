import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final result = <String, String>{};
  for (final entry in json.entries) {
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      result.addAll(_flatten(value, '$prefix${entry.key}.'));
    } else {
      result['$prefix${entry.key}'] = value.toString();
    }
  }
  return result;
}

Map<String, String> _load(String language) {
  final file = File('assets/translations/$language.json');
  return _flatten(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
}

void main() {
  final english = _load('en');
  final german = _load('de');
  final turkish = _load('tr');

  test('Englisch und Deutsch haben dieselben Schlüssel', () {
    expect(german.keys.toSet(), english.keys.toSet());
    expect(turkish.keys.toSet(), english.keys.toSet());
  });

  test('Platzhalter {name} stimmen in beiden Sprachen überein', () {
    final placeholder = RegExp(r'(?<!\{)\{(\w+)\}(?!\})');
    Set<String> namesIn(String text) =>
        placeholder.allMatches(text).map((m) => m.group(1)!).toSet();

    for (final key in english.keys) {
      expect(namesIn(german[key]!), namesIn(english[key]!), reason: key);
      expect(namesIn(turkish[key]!), namesIn(english[key]!), reason: 'tr $key');
    }
  });

  test('Texte sind nicht leer (außer dem Plugin-Platzhalter)', () {
    for (final translations in [english, german, turkish]) {
      final empty = translations.entries
          .where((entry) => entry.value.trim().isEmpty)
          .map((entry) => entry.key);
      expect(empty, ['task_builder.primitives.plugin.description']);
    }
  });

  test(
    'Standardnamen beginnen groß, sind ASCII und als {{name}} referenzierbar',
    () {
      final identifier = RegExp(r'^[A-Z][A-Za-z0-9_]*$');
      for (final translations in [english, german, turkish]) {
        final names = translations.entries
            .where(
              (entry) =>
                  entry.key.startsWith('task_builder.output_names.') ||
                  entry.key.startsWith('task_builder.send_output_names.'),
            )
            .map((entry) => entry.value);
        expect(names, isNotEmpty);
        expect(names.where((name) => !identifier.hasMatch(name)), isEmpty);
      }
    },
  );

  test('Standardnamen sind beispielhaft wie erwartet', () {
    expect(english['task_builder.output_names.string_input'], 'Input');
    expect(english['task_builder.send_output_names.email'], 'SendEmail');
    expect(german['task_builder.output_names.prompt'], 'Text');
    expect(german['task_builder.output_names.prompt_decision'], 'Antwort');
    expect(german['task_builder.send_output_names.email'], 'SendenEmail');
  });
}
