import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

import 'shopware_action_spec.dart';

/// Alle Aktionen des Shopware-Bausteins. Eine neue Aktion braucht hier einen
/// Eintrag und im Backend eine Datei unter `integrations/shopware/actions`.
class ShopwareActions {
  const ShopwareActions._();

  static const searchOrders = ShopwareActionSpec(
    id: 'searchOrders',
    title: 'Bestellungen suchen',
    description:
        'Holt Bestellungen aus Shopware, z. B. alle neuen der letzten Stunde.',
    outputBase: 'bestellungen',
    primaryOutput: NodeOutputType.json,
    secondaryOutputs: {
      'count': NodeOutputType.number,
      'total': NodeOutputType.number,
      'found': NodeOutputType.boolean,
    },
    initialParams: {'sort': 'newest', 'limit': 50},
    fields: [
      ShopwareField.text(
        'createdFrom',
        'Bestellt ab',
        hint: '2026-10-01 oder {{start}}',
        helper: 'Datum oder Zeitpunkt (ISO 8601). Leer: keine Untergrenze.',
      ),
      ShopwareField.text(
        'createdTo',
        'Bestellt bis',
        hint: '2026-10-31T23:59:59',
        helper: 'Leer: keine Obergrenze.',
      ),
      ShopwareField.select('status', 'Bestellstatus', [
        ShopwareFieldOption('', 'Beliebig'),
        ShopwareFieldOption('open', 'Offen'),
        ShopwareFieldOption('in_progress', 'In Bearbeitung'),
        ShopwareFieldOption('completed', 'Abgeschlossen'),
        ShopwareFieldOption('cancelled', 'Storniert'),
      ]),
      ShopwareField.select('paymentStatus', 'Zahlungsstatus', [
        ShopwareFieldOption('', 'Beliebig'),
        ShopwareFieldOption('open', 'Offen'),
        ShopwareFieldOption('paid', 'Bezahlt'),
        ShopwareFieldOption('paid_partially', 'Teilweise bezahlt'),
        ShopwareFieldOption('refunded', 'Erstattet'),
        ShopwareFieldOption('refunded_partially', 'Teilweise erstattet'),
        ShopwareFieldOption('cancelled', 'Abgebrochen'),
        ShopwareFieldOption('reminded', 'Erinnert'),
        ShopwareFieldOption('failed', 'Fehlgeschlagen'),
        ShopwareFieldOption('authorized', 'Autorisiert'),
        ShopwareFieldOption('in_progress', 'In Bearbeitung'),
        ShopwareFieldOption('chargeback', 'Rückbuchung'),
        ShopwareFieldOption('unconfirmed', 'Unbestätigt'),
      ]),
      ShopwareField.select('deliveryStatus', 'Lieferstatus', [
        ShopwareFieldOption('', 'Beliebig'),
        ShopwareFieldOption('open', 'Offen'),
        ShopwareFieldOption('shipped', 'Versandt'),
        ShopwareFieldOption('shipped_partially', 'Teilweise versandt'),
        ShopwareFieldOption('returned', 'Retourniert'),
        ShopwareFieldOption('returned_partially', 'Teilweise retourniert'),
        ShopwareFieldOption('cancelled', 'Abgebrochen'),
      ]),
      ShopwareField.text('customerEmail', 'E-Mail des Kunden'),
      ShopwareField.text('orderNumber', 'Bestellnummer'),
      ShopwareField.select('sort', 'Reihenfolge', [
        ShopwareFieldOption('newest', 'Neueste zuerst'),
        ShopwareFieldOption('oldest', 'Älteste zuerst'),
      ]),
      ShopwareField.number(
        'limit',
        'Höchstanzahl',
        min: 1,
        max: 500,
        helper: '1 bis 500',
      ),
    ],
  );

  static const all = [searchOrders];

  static ShopwareActionSpec? byId(String id) {
    for (final action in all) {
      if (action.id == id) return action;
    }
    return null;
  }
}
