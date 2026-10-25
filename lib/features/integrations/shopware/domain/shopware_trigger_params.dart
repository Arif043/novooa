import 'package:equatable/equatable.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Die Ereignisse, die Shopware an novooa melden kann. Die Namen entsprechen
/// `event` im Backend (`integrations/shopware/triggers`); Texte sind
/// Übersetzungsschlüssel.
enum ShopwareTriggerEvent {
  orderPlaced(
    LocaleKeys.shopware_triggers_order_placed_label,
    LocaleKeys.shopware_triggers_order_placed_description,
  ),
  orderStatus(
    LocaleKeys.shopware_triggers_order_status_label,
    LocaleKeys.shopware_triggers_order_status_description,
  ),
  customerRegistered(
    LocaleKeys.shopware_triggers_customer_registered_label,
    LocaleKeys.shopware_triggers_customer_registered_description,
  ),
  stockLow(
    LocaleKeys.shopware_triggers_stock_low_label,
    LocaleKeys.shopware_triggers_stock_low_description,
  ),
  newsletterSubscribed(
    LocaleKeys.shopware_triggers_newsletter_subscribed_label,
    LocaleKeys.shopware_triggers_newsletter_subscribed_description,
  );

  const ShopwareTriggerEvent(this.labelKey, this.descriptionKey);

  final String labelKey;
  final String descriptionKey;
}

class ShopwareStateOption {
  const ShopwareStateOption(this.value, this.labelKey);

  final String value;
  final String labelKey;
}

/// Die drei Statusabläufe einer Bestellung. [value] ist der Name der Entität
/// in Shopware.
enum ShopwareStateScope {
  order('order', LocaleKeys.shopware_scopes_order, 'completed', [
    ShopwareStateOption('open', LocaleKeys.shopware_states_open),
    ShopwareStateOption('in_progress', LocaleKeys.shopware_states_in_progress),
    ShopwareStateOption('completed', LocaleKeys.shopware_states_completed),
    ShopwareStateOption(
      'cancelled',
      LocaleKeys.shopware_states_order_cancelled,
    ),
  ]),
  payment('order_transaction', LocaleKeys.shopware_scopes_payment, 'paid', [
    ShopwareStateOption('open', LocaleKeys.shopware_states_open),
    ShopwareStateOption('authorized', LocaleKeys.shopware_states_authorized),
    ShopwareStateOption('paid', LocaleKeys.shopware_states_paid),
    ShopwareStateOption(
      'paid_partially',
      LocaleKeys.shopware_states_paid_partially,
    ),
    ShopwareStateOption('refunded', LocaleKeys.shopware_states_refunded),
    ShopwareStateOption(
      'refunded_partially',
      LocaleKeys.shopware_states_refunded_partially,
    ),
    ShopwareStateOption('cancelled', LocaleKeys.shopware_states_cancelled),
    ShopwareStateOption('failed', LocaleKeys.shopware_states_failed),
    ShopwareStateOption('reminded', LocaleKeys.shopware_states_reminded),
    ShopwareStateOption('unconfirmed', LocaleKeys.shopware_states_unconfirmed),
    ShopwareStateOption('chargeback', LocaleKeys.shopware_states_chargeback),
    ShopwareStateOption('in_progress', LocaleKeys.shopware_states_in_progress),
  ]),
  delivery('order_delivery', LocaleKeys.shopware_scopes_delivery, 'shipped', [
    ShopwareStateOption('open', LocaleKeys.shopware_states_open),
    ShopwareStateOption('shipped', LocaleKeys.shopware_states_shipped),
    ShopwareStateOption(
      'shipped_partially',
      LocaleKeys.shopware_states_shipped_partially,
    ),
    ShopwareStateOption('returned', LocaleKeys.shopware_states_returned),
    ShopwareStateOption(
      'returned_partially',
      LocaleKeys.shopware_states_returned_partially,
    ),
    ShopwareStateOption('cancelled', LocaleKeys.shopware_states_cancelled),
  ]);

  const ShopwareStateScope(
    this.value,
    this.labelKey,
    this.defaultState,
    this.states,
  );

  final String value;
  final String labelKey;
  final String defaultState;
  final List<ShopwareStateOption> states;

  /// Schlüssel des Status; `null`, wenn der Ablauf ihn nicht kennt.
  String? stateLabelKey(String state) {
    for (final option in states) {
      if (option.value == state) return option.labelKey;
    }
    return null;
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
