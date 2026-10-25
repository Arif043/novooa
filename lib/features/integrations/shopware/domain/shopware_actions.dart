import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

import 'shopware_action_spec.dart';

/// Alle Aktionen des Shopware-Bausteins. Eine neue Aktion braucht hier einen
/// Eintrag und im Backend eine Datei unter `integrations/shopware/actions`.
class ShopwareActions {
  const ShopwareActions._();

  static const searchOrders = ShopwareActionSpec(
    id: 'searchOrders',
    titleKey: LocaleKeys.shopware_actions_search_orders_title,
    descriptionKey: LocaleKeys.shopware_actions_search_orders_description,
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
        LocaleKeys.shopware_fields_created_from,
        hintKey: LocaleKeys.shopware_fields_created_from_hint,
        helperKey: LocaleKeys.shopware_fields_created_from_helper,
      ),
      ShopwareField.text(
        'createdTo',
        LocaleKeys.shopware_fields_created_to,
        hintKey: LocaleKeys.shopware_fields_created_to_hint,
        helperKey: LocaleKeys.shopware_fields_no_upper_limit,
      ),
      ShopwareField.select('status', LocaleKeys.shopware_fields_order_status, [
        ShopwareFieldOption('', LocaleKeys.shopware_options_any),
        ShopwareFieldOption('open', LocaleKeys.shopware_states_open),
        ShopwareFieldOption(
          'in_progress',
          LocaleKeys.shopware_states_in_progress,
        ),
        ShopwareFieldOption('completed', LocaleKeys.shopware_states_completed),
        ShopwareFieldOption(
          'cancelled',
          LocaleKeys.shopware_states_order_cancelled,
        ),
      ]),
      ShopwareField.select(
        'paymentStatus',
        LocaleKeys.shopware_fields_payment_status,
        [
          ShopwareFieldOption('', LocaleKeys.shopware_options_any),
          ShopwareFieldOption('open', LocaleKeys.shopware_states_open),
          ShopwareFieldOption('paid', LocaleKeys.shopware_states_paid),
          ShopwareFieldOption(
            'paid_partially',
            LocaleKeys.shopware_states_paid_partially,
          ),
          ShopwareFieldOption('refunded', LocaleKeys.shopware_states_refunded),
          ShopwareFieldOption(
            'refunded_partially',
            LocaleKeys.shopware_states_refunded_partially,
          ),
          ShopwareFieldOption(
            'cancelled',
            LocaleKeys.shopware_states_cancelled,
          ),
          ShopwareFieldOption('reminded', LocaleKeys.shopware_states_reminded),
          ShopwareFieldOption('failed', LocaleKeys.shopware_states_failed),
          ShopwareFieldOption(
            'authorized',
            LocaleKeys.shopware_states_authorized,
          ),
          ShopwareFieldOption(
            'in_progress',
            LocaleKeys.shopware_states_in_progress,
          ),
          ShopwareFieldOption(
            'chargeback',
            LocaleKeys.shopware_states_chargeback,
          ),
          ShopwareFieldOption(
            'unconfirmed',
            LocaleKeys.shopware_states_unconfirmed,
          ),
        ],
      ),
      ShopwareField.select(
        'deliveryStatus',
        LocaleKeys.shopware_fields_delivery_status,
        [
          ShopwareFieldOption('', LocaleKeys.shopware_options_any),
          ShopwareFieldOption('open', LocaleKeys.shopware_states_open),
          ShopwareFieldOption('shipped', LocaleKeys.shopware_states_shipped),
          ShopwareFieldOption(
            'shipped_partially',
            LocaleKeys.shopware_states_shipped_partially,
          ),
          ShopwareFieldOption('returned', LocaleKeys.shopware_states_returned),
          ShopwareFieldOption(
            'returned_partially',
            LocaleKeys.shopware_states_returned_partially,
          ),
          ShopwareFieldOption(
            'cancelled',
            LocaleKeys.shopware_states_cancelled,
          ),
        ],
      ),
      ShopwareField.text(
        'customerEmail',
        LocaleKeys.shopware_fields_customer_email,
      ),
      ShopwareField.text(
        'orderNumber',
        LocaleKeys.shopware_fields_order_number,
      ),
      ShopwareField.select('sort', LocaleKeys.shopware_fields_sort, [
        ShopwareFieldOption('newest', LocaleKeys.shopware_options_newest_first),
        ShopwareFieldOption('oldest', LocaleKeys.shopware_options_oldest_first),
      ]),
      ShopwareField.number(
        'limit',
        LocaleKeys.shopware_fields_limit,
        min: 1,
        max: 500,
        helperKey: LocaleKeys.shopware_fields_limit_helper,
      ),
    ],
  );

  static const _orderFields = [
    ShopwareField.text(
      'orderNumber',
      LocaleKeys.shopware_fields_order_number,
      hintKey: LocaleKeys.shopware_fields_order_number_hint,
    ),
    ShopwareField.text(
      'orderId',
      LocaleKeys.shopware_fields_order_id,
      helperKey: LocaleKeys.shopware_fields_order_id_helper,
    ),
  ];

  static const _anyOrYes = [
    ShopwareFieldOption('', LocaleKeys.shopware_options_any),
    ShopwareFieldOption('true', LocaleKeys.shopware_options_yes),
    ShopwareFieldOption('false', LocaleKeys.shopware_options_no),
  ];

  static const _listOutputs = {
    'count': NodeOutputType.number,
    'total': NodeOutputType.number,
    'found': NodeOutputType.boolean,
  };

  static const getOrder = ShopwareActionSpec(
    id: 'getOrder',
    titleKey: LocaleKeys.shopware_actions_get_order_title,
    descriptionKey: LocaleKeys.shopware_actions_get_order_description,
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
    titleKey: LocaleKeys.shopware_actions_change_order_status_title,
    descriptionKey: LocaleKeys.shopware_actions_change_order_status_description,
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
        LocaleKeys.shopware_fields_transition,
        [
          ShopwareFieldOption('', LocaleKeys.shopware_options_please_choose),
          ShopwareFieldOption(
            'order.process',
            LocaleKeys.shopware_transitions_order_process,
          ),
          ShopwareFieldOption(
            'order.complete',
            LocaleKeys.shopware_transitions_order_complete,
          ),
          ShopwareFieldOption(
            'order.cancel',
            LocaleKeys.shopware_transitions_order_cancel,
          ),
          ShopwareFieldOption(
            'order.reopen',
            LocaleKeys.shopware_transitions_order_reopen,
          ),
          ShopwareFieldOption(
            'payment.paid',
            LocaleKeys.shopware_transitions_payment_paid,
          ),
          ShopwareFieldOption(
            'payment.paid_partially',
            LocaleKeys.shopware_transitions_payment_paid_partially,
          ),
          ShopwareFieldOption(
            'payment.refund',
            LocaleKeys.shopware_transitions_payment_refund,
          ),
          ShopwareFieldOption(
            'payment.refund_partially',
            LocaleKeys.shopware_transitions_payment_refund_partially,
          ),
          ShopwareFieldOption(
            'payment.cancel',
            LocaleKeys.shopware_transitions_payment_cancel,
          ),
          ShopwareFieldOption(
            'payment.reopen',
            LocaleKeys.shopware_transitions_payment_reopen,
          ),
          ShopwareFieldOption(
            'payment.remind',
            LocaleKeys.shopware_transitions_payment_remind,
          ),
          ShopwareFieldOption(
            'payment.fail',
            LocaleKeys.shopware_transitions_payment_fail,
          ),
          ShopwareFieldOption(
            'payment.authorize',
            LocaleKeys.shopware_transitions_payment_authorize,
          ),
          ShopwareFieldOption(
            'payment.chargeback',
            LocaleKeys.shopware_transitions_payment_chargeback,
          ),
          ShopwareFieldOption(
            'delivery.ship',
            LocaleKeys.shopware_transitions_delivery_ship,
          ),
          ShopwareFieldOption(
            'delivery.ship_partially',
            LocaleKeys.shopware_transitions_delivery_ship_partially,
          ),
          ShopwareFieldOption(
            'delivery.retour',
            LocaleKeys.shopware_transitions_delivery_retour,
          ),
          ShopwareFieldOption(
            'delivery.cancel',
            LocaleKeys.shopware_transitions_delivery_cancel,
          ),
          ShopwareFieldOption(
            'delivery.reopen',
            LocaleKeys.shopware_transitions_delivery_reopen,
          ),
        ],
        helperKey: LocaleKeys.shopware_fields_transition_helper,
      ),
      ShopwareField.toggle(
        'sendMail',
        LocaleKeys.shopware_fields_send_mail,
        helperKey: LocaleKeys.shopware_fields_send_mail_helper,
      ),
    ],
  );

  static const searchProducts = ShopwareActionSpec(
    id: 'searchProducts',
    titleKey: LocaleKeys.shopware_actions_search_products_title,
    descriptionKey: LocaleKeys.shopware_actions_search_products_description,
    outputBase: 'produkte',
    primaryOutput: NodeOutputType.json,
    outputFields: _listOutputs,
    initialParams: {'sort': 'name', 'limit': 50},
    fields: [
      ShopwareField.text('name', LocaleKeys.shopware_fields_name_contains),
      ShopwareField.text(
        'productNumber',
        LocaleKeys.shopware_fields_product_number,
      ),
      ShopwareField.select(
        'active',
        LocaleKeys.shopware_fields_active,
        _anyOrYes,
      ),
      ShopwareField.number(
        'stockMin',
        LocaleKeys.shopware_fields_stock_min,
        min: -1000000,
        max: 1000000000,
        helperKey: LocaleKeys.shopware_fields_no_lower_limit,
      ),
      ShopwareField.number(
        'stockMax',
        LocaleKeys.shopware_fields_stock_max,
        min: -1000000,
        max: 1000000000,
        helperKey: LocaleKeys.shopware_fields_no_upper_limit,
      ),
      ShopwareField.select('sort', LocaleKeys.shopware_fields_sort, [
        ShopwareFieldOption('name', LocaleKeys.shopware_options_name_ascending),
        ShopwareFieldOption('newest', LocaleKeys.shopware_options_newest_first),
        ShopwareFieldOption(
          'stock',
          LocaleKeys.shopware_options_lowest_stock_first,
        ),
      ]),
      ShopwareField.number(
        'limit',
        LocaleKeys.shopware_fields_limit,
        min: 1,
        max: 500,
        helperKey: LocaleKeys.shopware_fields_limit_helper,
      ),
    ],
  );

  static const updateProduct = ShopwareActionSpec(
    id: 'updateProduct',
    titleKey: LocaleKeys.shopware_actions_update_product_title,
    descriptionKey: LocaleKeys.shopware_actions_update_product_description,
    outputBase: 'produkt',
    primaryOutput: NodeOutputType.json,
    outputFields: {'changed': NodeOutputType.boolean},
    fields: [
      ShopwareField.text(
        'productNumber',
        LocaleKeys.shopware_fields_product_number,
      ),
      ShopwareField.text(
        'productId',
        LocaleKeys.shopware_fields_product_id,
        helperKey: LocaleKeys.shopware_fields_product_id_helper,
      ),
      ShopwareField.number(
        'stock',
        LocaleKeys.shopware_fields_new_stock,
        min: 0,
        max: 1000000000,
        helperKey: LocaleKeys.shopware_fields_unchanged_if_empty,
      ),
      ShopwareField.text(
        'price',
        LocaleKeys.shopware_fields_new_price,
        hintKey: LocaleKeys.shopware_fields_new_price_hint,
        helperKey: LocaleKeys.shopware_fields_new_price_helper,
      ),
      ShopwareField.select('active', LocaleKeys.shopware_fields_active, [
        ShopwareFieldOption('', LocaleKeys.shopware_options_unchanged),
        ShopwareFieldOption('true', LocaleKeys.shopware_fields_active),
        ShopwareFieldOption('false', LocaleKeys.shopware_options_inactive),
      ]),
    ],
  );

  static const searchCustomers = ShopwareActionSpec(
    id: 'searchCustomers',
    titleKey: LocaleKeys.shopware_actions_search_customers_title,
    descriptionKey: LocaleKeys.shopware_actions_search_customers_description,
    outputBase: 'kunden',
    primaryOutput: NodeOutputType.json,
    outputFields: _listOutputs,
    initialParams: {'sort': 'newest', 'limit': 50},
    fields: [
      ShopwareField.text('email', LocaleKeys.shopware_fields_email_contains),
      ShopwareField.text(
        'name',
        LocaleKeys.shopware_fields_name_contains,
        helperKey: LocaleKeys.shopware_fields_customer_name_helper,
      ),
      ShopwareField.text(
        'customerNumber',
        LocaleKeys.shopware_fields_customer_number,
      ),
      ShopwareField.select(
        'active',
        LocaleKeys.shopware_fields_active,
        _anyOrYes,
      ),
      ShopwareField.select('sort', LocaleKeys.shopware_fields_sort, [
        ShopwareFieldOption('newest', LocaleKeys.shopware_options_newest_first),
        ShopwareFieldOption(
          'name',
          LocaleKeys.shopware_options_last_name_ascending,
        ),
      ]),
      ShopwareField.number(
        'limit',
        LocaleKeys.shopware_fields_limit,
        min: 1,
        max: 500,
        helperKey: LocaleKeys.shopware_fields_limit_helper,
      ),
    ],
  );

  static const query = ShopwareActionSpec(
    id: 'query',
    titleKey: LocaleKeys.shopware_actions_query_title,
    descriptionKey: LocaleKeys.shopware_actions_query_description,
    outputBase: 'abfrage',
    primaryOutput: NodeOutputType.json,
    outputFields: _listOutputs,
    initialParams: {'limit': 50, 'page': 1},
    fields: [
      ShopwareField.text(
        'entity',
        LocaleKeys.shopware_fields_entity,
        hintKey: LocaleKeys.shopware_fields_entity_hint,
        helperKey: LocaleKeys.shopware_fields_entity_helper,
      ),
      ShopwareField.text(
        'criteria',
        LocaleKeys.shopware_fields_criteria,
        lines: 6,
        hintKey: LocaleKeys.shopware_fields_criteria_hint,
        helperKey: LocaleKeys.shopware_fields_criteria_helper,
      ),
      ShopwareField.number(
        'page',
        LocaleKeys.shopware_fields_page,
        min: 1,
        max: 100000,
      ),
      ShopwareField.number(
        'limit',
        LocaleKeys.shopware_fields_limit,
        min: 1,
        max: 500,
        helperKey: LocaleKeys.shopware_fields_limit_helper,
      ),
    ],
  );

  static const readEvent = ShopwareActionSpec(
    id: 'readEvent',
    titleKey: LocaleKeys.shopware_actions_read_event_title,
    descriptionKey: LocaleKeys.shopware_actions_read_event_description,
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
