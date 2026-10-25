import 'package:easy_localization/easy_localization.dart';
import 'package:simple_icons/simple_icons.dart';
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
        title: action.titleKey.tr,
        description: action.descriptionKey.tr,
        group: 'Shopware',
        icon: SimpleIcons.shopware,
        outputBase: action.outputBase,
        initial: () => ShopwareNodeConfig.initial(action.id),
        fromDocument: ShopwareNodeConfig.fromDocument,
        builder: (node) => ShopwareActionWidget(node: node),
      ),
    );
  }
}
