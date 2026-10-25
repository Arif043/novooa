import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../domain/shopware_trigger_params.dart';

/// Übersetzte Texte eines Shopware-Auslösers; die Domain liefert nur Schlüssel.
extension ShopwareTriggerTexts on ShopwareTriggerParams {
  /// Kurzbeschreibung für die Auslöser-Karte und die Shopware-App.
  String get summary => switch (event) {
    ShopwareTriggerEvent.orderStatus =>
      '${scope.labelKey.tr()}: ${stateLabel(scope, state)}',
    ShopwareTriggerEvent.stockLow =>
      LocaleKeys.shopware_ui_summary_stock_at_most.tr(
        namedArgs: {'threshold': '$threshold'},
      ),
    ShopwareTriggerEvent.newsletterSubscribed =>
      confirmedOnly
          ? LocaleKeys.shopware_ui_summary_newsletter_confirmed.tr()
          : event.labelKey.tr(),
    _ => event.labelKey.tr(),
  };
}

/// Ein unbekannter Status erscheint mit seinem Namen aus Shopware.
String stateLabel(ShopwareStateScope scope, String state) =>
    scope.stateLabelKey(state)?.tr() ?? state;
