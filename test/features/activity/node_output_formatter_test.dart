import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/presentation/widgets/node_output_formatter.dart';

import '../../helpers/test_translations.dart';

void main() {
  test('Feldnamen der Bausteine sind übersetzt, eigene Feldnamen bleiben', () {
    expect(NodeOutputFormatter.labelFor('found'), 'Gefunden');
    expect(NodeOutputFormatter.labelFor('record'), 'Datensatz');
    expect(NodeOutputFormatter.labelFor('orderNumber'), 'Bestellnummer');
    expect(NodeOutputFormatter.labelFor('Rechnungsnummer'), 'Rechnungsnummer');
  });

  test('Ja, Nein und fehlende Werte folgen der App-Sprache', () {
    expect(NodeOutputFormatter.formatValue(true), 'Ja');
    expect(NodeOutputFormatter.formatValue(null), 'Keine Angabe');

    loadTestTranslations(const Locale('en'));
    addTearDown(() => loadTestTranslations(const Locale('de')));

    expect(NodeOutputFormatter.labelFor('found'), 'Found');
    expect(NodeOutputFormatter.labelFor('record'), 'Record');
    expect(NodeOutputFormatter.formatValue(false), 'No');
    expect(NodeOutputFormatter.formatValue(null), 'Not specified');
  });
}
