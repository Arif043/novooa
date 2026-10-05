import 'package:equatable/equatable.dart';

/// Die Ereignisse, die Shopware an novooa melden kann. Die Namen entsprechen
/// `event` im Backend (`integrations/shopware/triggers`).
enum ShopwareTriggerEvent {
  orderPlaced('Neue Bestellung', 'Eine Bestellung wurde aufgegeben.'),
  orderStatus(
    'Bestellstatus erreicht',
    'Bestellung, Zahlung oder Lieferung erreicht einen Status.',
  ),
  customerRegistered('Neuer Kunde', 'Ein Kunde hat sich registriert.'),
  stockLow(
    'Bestand unterschritten',
    'Der Bestand eines Produkts erreicht die Grenze oder liegt darunter.',
  ),
  newsletterSubscribed(
    'Newsletter-Anmeldung',
    'Jemand hat sich für den Newsletter angemeldet.',
  );

  const ShopwareTriggerEvent(this.label, this.description);

  final String label;
  final String description;
}

class ShopwareStateOption {
  const ShopwareStateOption(this.value, this.label);

  final String value;
  final String label;
}

/// Die drei Statusabläufe einer Bestellung. [value] ist der Name der Entität
/// in Shopware.
enum ShopwareStateScope {
  order('order', 'Bestellung', 'completed', [
    ShopwareStateOption('open', 'Offen'),
    ShopwareStateOption('in_progress', 'In Bearbeitung'),
    ShopwareStateOption('completed', 'Abgeschlossen'),
    ShopwareStateOption('cancelled', 'Storniert'),
  ]),
  payment('order_transaction', 'Zahlung', 'paid', [
    ShopwareStateOption('open', 'Offen'),
    ShopwareStateOption('authorized', 'Autorisiert'),
    ShopwareStateOption('paid', 'Bezahlt'),
    ShopwareStateOption('paid_partially', 'Teilweise bezahlt'),
    ShopwareStateOption('refunded', 'Erstattet'),
    ShopwareStateOption('refunded_partially', 'Teilweise erstattet'),
    ShopwareStateOption('cancelled', 'Abgebrochen'),
    ShopwareStateOption('failed', 'Fehlgeschlagen'),
    ShopwareStateOption('reminded', 'Erinnert'),
    ShopwareStateOption('unconfirmed', 'Unbestätigt'),
    ShopwareStateOption('chargeback', 'Rückbuchung'),
    ShopwareStateOption('in_progress', 'In Bearbeitung'),
  ]),
  delivery('order_delivery', 'Lieferung', 'shipped', [
    ShopwareStateOption('open', 'Offen'),
    ShopwareStateOption('shipped', 'Versandt'),
    ShopwareStateOption('shipped_partially', 'Teilweise versandt'),
    ShopwareStateOption('returned', 'Retourniert'),
    ShopwareStateOption('returned_partially', 'Teilweise retourniert'),
    ShopwareStateOption('cancelled', 'Abgebrochen'),
  ]);

  const ShopwareStateScope(
    this.value,
    this.label,
    this.defaultState,
    this.states,
  );

  final String value;
  final String label;
  final String defaultState;
  final List<ShopwareStateOption> states;

  String stateLabel(String state) {
    for (final option in states) {
      if (option.value == state) return option.label;
    }
    return state;
  }
}

/// Einstellungen eines Shopware-Auslösers (`eventConfig.params`).
class ShopwareTriggerParams extends Equatable {
  const ShopwareTriggerParams({
    this.event = ShopwareTriggerEvent.orderPlaced,
    this.connectionId = '',
    this.scope = ShopwareStateScope.payment,
    this.state = 'paid',
    this.threshold = 5,
    this.confirmedOnly = true,
  });

  factory ShopwareTriggerParams.fromMap(Map<String, Object?> data) {
    final scope = ShopwareStateScope.values.firstWhere(
      (item) => item.value == data['scope'],
      orElse: () => ShopwareStateScope.payment,
    );
    final state = data['state'];
    return ShopwareTriggerParams(
      event: ShopwareTriggerEvent.values.firstWhere(
        (item) => item.name == data['event'],
        orElse: () => ShopwareTriggerEvent.orderPlaced,
      ),
      connectionId: data['connectionId'] as String? ?? '',
      scope: scope,
      state: state is String && state.isNotEmpty ? state : scope.defaultState,
      threshold: data['threshold'] is num
          ? (data['threshold'] as num).toInt()
          : 5,
      confirmedOnly: data['confirmedOnly'] != false,
    );
  }

  final ShopwareTriggerEvent event;
  final String connectionId;
  final ShopwareStateScope scope;
  final String state;
  final int threshold;
  final bool confirmedOnly;

  bool get isComplete =>
      connectionId.isNotEmpty &&
      (event != ShopwareTriggerEvent.orderStatus ||
          scope.states.any((option) => option.value == state));

  ShopwareTriggerParams copyWith({
    ShopwareTriggerEvent? event,
    String? connectionId,
    ShopwareStateScope? scope,
    String? state,
    int? threshold,
    bool? confirmedOnly,
  }) {
    final nextScope = scope ?? this.scope;
    return ShopwareTriggerParams(
      event: event ?? this.event,
      connectionId: connectionId ?? this.connectionId,
      scope: nextScope,
      // Ein Zustand gilt nur im Ablauf, für den er gewählt wurde.
      state:
          state ??
          (nextScope == this.scope ? this.state : nextScope.defaultState),
      threshold: threshold ?? this.threshold,
      confirmedOnly: confirmedOnly ?? this.confirmedOnly,
    );
  }

  /// Nur, was für das Ereignis gilt; das Backend prüft dasselbe.
  Map<String, Object?> toMap() => {
    'event': event.name,
    'connectionId': connectionId,
    if (event == ShopwareTriggerEvent.orderStatus) ...{
      'scope': scope.value,
      'state': state,
    },
    if (event == ShopwareTriggerEvent.stockLow) 'threshold': threshold,
    if (event == ShopwareTriggerEvent.newsletterSubscribed)
      'confirmedOnly': confirmedOnly,
  };

  /// Kurzbeschreibung für die Auslöser-Karte.
  String get summary => switch (event) {
    ShopwareTriggerEvent.orderStatus =>
      '${scope.label}: ${scope.stateLabel(state)}',
    ShopwareTriggerEvent.stockLow => 'Bestand höchstens $threshold',
    ShopwareTriggerEvent.newsletterSubscribed =>
      confirmedOnly ? 'Newsletter-Anmeldung bestätigt' : 'Newsletter-Anmeldung',
    _ => event.label,
  };

  /// Name des Ereignisses, auf das die Shopware-App lauscht.
  String get webhookEvent => switch (event) {
    ShopwareTriggerEvent.orderPlaced => 'checkout.order.placed',
    ShopwareTriggerEvent.orderStatus =>
      'state_enter.${scope.value}.state.$state',
    ShopwareTriggerEvent.customerRegistered => 'checkout.customer.register',
    ShopwareTriggerEvent.stockLow => 'product.written',
    ShopwareTriggerEvent.newsletterSubscribed =>
      confirmedOnly ? 'newsletter.confirmed' : 'newsletter.register',
  };

  /// Entitäten, die die App lesen darf, damit Shopware das Ereignis sendet.
  List<String> get readPermissions => switch (event) {
    ShopwareTriggerEvent.orderPlaced => const ['order'],
    ShopwareTriggerEvent.orderStatus => ['order', scope.value],
    ShopwareTriggerEvent.customerRegistered => const ['customer'],
    ShopwareTriggerEvent.stockLow => const ['product'],
    ShopwareTriggerEvent.newsletterSubscribed => const ['newsletter_recipient'],
  };

  @override
  List<Object?> get props => [
    event,
    connectionId,
    scope,
    state,
    threshold,
    confirmedOnly,
  ];
}
