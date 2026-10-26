import 'package:easy_localization/easy_localization.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/presentation/plugin_catalog.dart';
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';

import 'domain/shopware_actions.dart';
import 'domain/shopware_node_config.dart';
import 'presentation/widgets/shopware_action_widget.dart';

/// Kennung wie in der Runtime (`shopware-plugin.ts`).
const shopwarePluginId = 'shopware';

/// Meldet das Shopware-Plugin und seine Bausteine an: je Aktion ein Eintrag in der
/// Palette, alle teilen sich Konfiguration und Formular.
void registerShopwarePlugin() {
  PluginCatalog.register(
    PluginDescription(
      id: const PluginId(shopwarePluginId),
      title: LocaleKeys.shopware_plugin_title.tr,
      description: LocaleKeys.shopware_plugin_description.tr,
      icon: SimpleIcons.shopware,
    ),
  );
  for (final action in ShopwareActions.all) {
    PluginNodeModules.register(
      PluginNodeModule(
        pluginId: shopwarePluginId,
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
