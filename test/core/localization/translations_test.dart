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

  test('Englisch und Deutsch haben dieselben Schlüssel', () {
    expect(german.keys.toSet(), english.keys.toSet());
  });

  test('Texte sind nicht leer (außer dem Plugin-Platzhalter)', () {
    for (final translations in [english, german]) {
      final empty = translations.entries
          .where((entry) => entry.value.trim().isEmpty)
          .map((entry) => entry.key);
      expect(empty, ['task_builder.primitives.plugin.description']);
    }
  });

  test('Standardnamen sind ASCII und als {{name}} referenzierbar', () {
    final identifier = RegExp(r'^[A-Za-z][A-Za-z0-9_]*$');
    for (final translations in [english, german]) {
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
  });

  test('Englisch bleibt bei den bisherigen Standardnamen', () {
    expect(english['task_builder.output_names.string_input'], 'input');
    expect(english['task_builder.output_names.prompt'], 'prompt');
    expect(english['task_builder.send_output_names.email'], 'sendemail');
  });
}
