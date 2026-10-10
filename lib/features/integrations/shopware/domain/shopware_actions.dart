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
    outputFields: {
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

  static const _orderFields = [
    ShopwareField.text('orderNumber', 'Bestellnummer', hint: '10001'),
    ShopwareField.text(
      'orderId',
      'Bestell-ID (optional)',
      helper: 'Die 32-stellige Kennung. Sie hat Vorrang vor der Nummer.',
    ),
  ];

  static const _anyOrYes = [
    ShopwareFieldOption('', 'Beliebig'),
    ShopwareFieldOption('true', 'Ja'),
    ShopwareFieldOption('false', 'Nein'),
  ];

  static const _listOutputs = {
    'count': NodeOutputType.number,
    'total': NodeOutputType.number,
    'found': NodeOutputType.boolean,
  };

  static const getOrder = ShopwareActionSpec(
    id: 'getOrder',
    title: 'Bestellung lesen',
    description: 'Liest eine Bestellung über ihre Nummer oder Kennung.',
    outputBase: 'bestellung',
    primaryOutput: NodeOutputType.json,
    outputFields: {
      'orderNumber': NodeOutputType.string,
      'status': NodeOutputType.string,
      'paymentStatus': NodeOutputType.string,
      'deliveryStatus': NodeOutputType.string,
      'total': NodeOutputType.number,
      'customerEmail': NodeOutputType.string,
    },
    fields: _orderFields,
  );

  static const changeOrderStatus = ShopwareActionSpec(
    id: 'changeOrderStatus',
    title: 'Bestellstatus ändern',
    description:
        'Ändert den Status einer Bestellung, ihrer Zahlung oder ihrer Lieferung.',
    outputBase: 'statuswechsel',
    primaryOutput: NodeOutputType.json,
    outputFields: {
      'previousStatus': NodeOutputType.string,
      'newStatus': NodeOutputType.string,
      'changed': NodeOutputType.boolean,
    },
    fields: [
      ..._orderFields,
      ShopwareField.select(
        'transition',
        'Statuswechsel',
        [
          ShopwareFieldOption('', 'Bitte wählen'),
          ShopwareFieldOption(
            'order.process',
            'Bestellung: In Bearbeitung setzen',
          ),
          ShopwareFieldOption('order.complete', 'Bestellung: Abschließen'),
          ShopwareFieldOption('order.cancel', 'Bestellung: Stornieren'),
          ShopwareFieldOption('order.reopen', 'Bestellung: Wieder öffnen'),
          ShopwareFieldOption('payment.paid', 'Zahlung: Als bezahlt markieren'),
          ShopwareFieldOption(
            'payment.paid_partially',
            'Zahlung: Teilweise bezahlt',
          ),
          ShopwareFieldOption('payment.refund', 'Zahlung: Erstatten'),
          ShopwareFieldOption(
            'payment.refund_partially',
            'Zahlung: Teilweise erstatten',
          ),
          ShopwareFieldOption('payment.cancel', 'Zahlung: Abbrechen'),
          ShopwareFieldOption('payment.reopen', 'Zahlung: Wieder öffnen'),
          ShopwareFieldOption('payment.remind', 'Zahlung: Erinnern'),
          ShopwareFieldOption(
            'payment.fail',
            'Zahlung: Als fehlgeschlagen markieren',
          ),
          ShopwareFieldOption('payment.authorize', 'Zahlung: Autorisieren'),
          ShopwareFieldOption('payment.chargeback', 'Zahlung: Rückbuchung'),
          ShopwareFieldOption(
            'delivery.ship',
            'Lieferung: Als versandt markieren',
          ),
          ShopwareFieldOption(
            'delivery.ship_partially',
            'Lieferung: Teilweise versandt',
          ),
          ShopwareFieldOption('delivery.retour', 'Lieferung: Retoure'),
          ShopwareFieldOption('delivery.cancel', 'Lieferung: Abbrechen'),
          ShopwareFieldOption('delivery.reopen', 'Lieferung: Wieder öffnen'),
        ],
        helper:
            'Zahlung und Lieferung betreffen die jüngste Zahlung bzw. die erste Lieferung.',
      ),
      ShopwareField.toggle(
        'sendMail',
        'Mail an den Kunden senden',
        helper:
            'Shopware verschickt dabei die Mail der Vorlage für diesen Statuswechsel. Standardmäßig aus.',
      ),
    ],
  );

  static const searchProducts = ShopwareActionSpec(
    id: 'searchProducts',
    title: 'Produkte suchen',
    description: 'Holt Produkte aus Shopware, z. B. alle mit geringem Bestand.',
    outputBase: 'produkte',
    primaryOutput: NodeOutputType.json,
    outputFields: _listOutputs,
    initialParams: {'sort': 'name', 'limit': 50},
    fields: [
      ShopwareField.text('name', 'Name enthält'),
      ShopwareField.text('productNumber', 'Artikelnummer'),
      ShopwareField.select('active', 'Aktiv', _anyOrYes),
      ShopwareField.number(
        'stockMin',
        'Bestand ab',
        min: -1000000,
        max: 1000000000,
        helper: 'Leer: keine Untergrenze.',
      ),
      ShopwareField.number(
        'stockMax',
        'Bestand bis',
        min: -1000000,
        max: 1000000000,
        helper: 'Leer: keine Obergrenze.',
      ),
      ShopwareField.select('sort', 'Reihenfolge', [
        ShopwareFieldOption('name', 'Name (A–Z)'),
        ShopwareFieldOption('newest', 'Neueste zuerst'),
        ShopwareFieldOption('stock', 'Geringster Bestand zuerst'),
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

  static const updateProduct = ShopwareActionSpec(
    id: 'updateProduct',
    title: 'Produkt ändern',
    description: 'Ändert Bestand, Preis oder Aktiv-Status eines Produkts.',
    outputBase: 'produkt',
    primaryOutput: NodeOutputType.json,
    outputFields: {'changed': NodeOutputType.boolean},
    fields: [
      ShopwareField.text('productNumber', 'Artikelnummer'),
      ShopwareField.text(
        'productId',
        'Produkt-ID (optional)',
        helper:
            'Die 32-stellige Kennung. Sie hat Vorrang vor der Artikelnummer.',
      ),
      ShopwareField.number(
        'stock',
        'Neuer Bestand',
        min: 0,
        max: 1000000000,
        helper: 'Leer: nicht ändern.',
      ),
      ShopwareField.text(
        'price',
        'Neuer Preis (brutto)',
        hint: '19,99',
        helper:
            'Leer: nicht ändern. Den Nettopreis berechnet novooa aus dem Steuersatz des Produkts.',
      ),
      ShopwareField.select('active', 'Aktiv', [
        ShopwareFieldOption('', 'Nicht ändern'),
        ShopwareFieldOption('true', 'Aktiv'),
        ShopwareFieldOption('false', 'Inaktiv'),
      ]),
    ],
  );

  static const searchCustomers = ShopwareActionSpec(
    id: 'searchCustomers',
    title: 'Kunden suchen',
    description: 'Holt Kunden aus Shopware, z. B. über E-Mail oder Name.',
    outputBase: 'kunden',
    primaryOutput: NodeOutputType.json,
    outputFields: _listOutputs,
    initialParams: {'sort': 'newest', 'limit': 50},
    fields: [
      ShopwareField.text('email', 'E-Mail enthält'),
      ShopwareField.text(
        'name',
        'Name enthält',
        helper: 'Sucht in Vorname, Nachname und Firma.',
      ),
      ShopwareField.text('customerNumber', 'Kundennummer'),
      ShopwareField.select('active', 'Aktiv', _anyOrYes),
      ShopwareField.select('sort', 'Reihenfolge', [
        ShopwareFieldOption('newest', 'Neueste zuerst'),
        ShopwareFieldOption('name', 'Nachname (A–Z)'),
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

  static const query = ShopwareActionSpec(
    id: 'query',
    title: 'Shopware-Abfrage',
    description:
        'Fragt eine beliebige Shopware-Entität mit eigenen Kriterien ab (nur lesend).',
    outputBase: 'abfrage',
    primaryOutput: NodeOutputType.json,
    outputFields: _listOutputs,
    initialParams: {'limit': 50, 'page': 1},
    fields: [
      ShopwareField.text(
        'entity',
        'Entität',
        hint: 'order',
        helper: 'Name in Shopware, z. B. order, product, customer oder tax.',
      ),
      ShopwareField.text(
        'criteria',
        'Kriterien (JSON)',
        lines: 6,
        hint:
            '{"filter": [{"type": "equals", "field": "active", "value": true}]}',
        helper:
            'Shopware-Suchkriterien ohne limit und page. Leer: keine Filter.',
      ),
      ShopwareField.number('page', 'Seite', min: 1, max: 100000),
      ShopwareField.number(
        'limit',
        'Höchstanzahl',
        min: 1,
        max: 500,
        helper: '1 bis 500',
      ),
    ],
  );

  static const readEvent = ShopwareActionSpec(
    id: 'readEvent',
    title: 'Shopware-Ereignis lesen',
    description:
        'Macht Bestellung, Kunde, Produkt oder Anmeldung eines Shopware-Auslösers nutzbar.',
    outputBase: 'ereignis',
    primaryOutput: NodeOutputType.json,
    outputFields: {
      'event': NodeOutputType.string,
      'id': NodeOutputType.string,
      'receivedAt': NodeOutputType.datetime,
    },
    usesConnection: false,
    fields: [],
  );

  static const all = [
    searchOrders,
    getOrder,
    changeOrderStatus,
    searchProducts,
    updateProduct,
    searchCustomers,
    query,
    readEvent,
  ];

  static ShopwareActionSpec? byId(String id) {
    for (final action in all) {
      if (action.id == id) return action;
    }
    return null;
  }
}
