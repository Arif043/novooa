import 'package:flutter/material.dart';
import 'package:syscat2/core/runtime/connections_availability.dart';
import 'package:syscat2/core/runtime/webhooks_availability.dart';
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';

import 'domain/shopware_actions.dart';
import 'domain/shopware_node_config.dart';
import 'presentation/widgets/shopware_action_widget.dart';

/// Meldet die Bausteine des Shopware-Plugins an: je Aktion ein Eintrag in der
/// Palette, alle teilen sich Konfiguration und Formular.
void registerShopwarePlugin() {
  for (final action in ShopwareActions.all) {
    PluginNodeModules.register(
      PluginNodeModule(
        typeId: 'shopware.${action.id}',
        documentPrimitive: 'shopware',
        title: action.title,
        description: action.description,
        group: 'Shopware',
        icon: Icons.storefront_outlined,
        outputBase: action.outputBase,
        initial: () => ShopwareNodeConfig.initial(action.id),
        fromDocument: ShopwareNodeConfig.fromDocument,
        builder: (node) => ShopwareActionWidget(node: node),
        // Die Aktionen brauchen Verbindungen, das Ereignis den Webhook-Empfänger
        // der lokalen Runtime.
        isAvailable: action.usesConnection
            ? connectionsAvailable
            : webhooksAvailable,
      ),
    );
  }
}
