import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_actions.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_trigger_params.dart';
import 'package:syscat2/features/integrations/shopware/presentation/shopware_trigger_texts.dart';

import '../../helpers/test_translations.dart';

Set<String> _shopwareKeys(String languageCode) {
  final file = File('assets/translations/$languageCode.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final keys = <String>{};
  void collect(Map<String, dynamic> node, String prefix) {
    for (final entry in node.entries) {
      final key = '$prefix.${entry.key}';
      final value = entry.value;
      value is Map<String, dynamic> ? collect(value, key) : keys.add(key);
    }
  }

  collect(json['shopware'] as Map<String, dynamic>, 'shopware');
  return keys;
}

void main() {
  tearDown(() => loadTestTranslations(const Locale('de')));

  test('jeder Shopware-Text gibt es auf Deutsch, Englisch und Türkisch', () {
    final german = _shopwareKeys('de');

    expect(_shopwareKeys('en'), german);
    expect(_shopwareKeys('tr'), german);
  });

  test('Aktionen, Felder und Auslöser erscheinen auf Englisch', () {
    loadTestTranslations(const Locale('en'));

    expect(ShopwareActions.searchOrders.titleKey.tr(), 'Search orders');
    expect(
      ShopwareActions.searchOrders.fields.last.labelKey.tr(),
      'Maximum results',
    );
    expect(
      const ShopwareTriggerParams(
        event: ShopwareTriggerEvent.stockLow,
        threshold: 4,
      ).summary,
      'Stock at most 4',
    );
    expect(
      const ShopwareTriggerParams(
        event: ShopwareTriggerEvent.orderStatus,
        scope: ShopwareStateScope.delivery,
        state: 'shipped',
      ).summary,
      'Delivery: Shipped',
    );
  });
}
