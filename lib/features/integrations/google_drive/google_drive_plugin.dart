import 'package:easy_localization/easy_localization.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/presentation/plugin_catalog.dart';
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';

import 'domain/google_drive_actions.dart';
import 'domain/google_drive_node_config.dart';
import 'presentation/widgets/google_drive_action_widget.dart';
import 'presentation/widgets/google_drive_plugin_settings.dart';

/// Kennung wie in der Runtime (`google-drive-plugin.ts`).
const googleDrivePluginId = 'googleDrive';

/// Meldet das Drive-Plugin samt Google-Konten als Einstellungen und seine
/// Bausteine an: je Aktion ein Eintrag in der Palette, alle teilen sich
/// Konfiguration und Formular.
void registerGoogleDrivePlugin() {
  PluginCatalog.register(
    PluginDescription(
      id: const PluginId(googleDrivePluginId),
      title: LocaleKeys.google_drive_plugin_title.tr,
      description: LocaleKeys.google_drive_plugin_description.tr,
      icon: SimpleIcons.googledrive,
      settingsBuilder: (_) => const GoogleDrivePluginSettings(),
    ),
  );
  for (final action in GoogleDriveActions.all) {
    PluginNodeModules.register(
      PluginNodeModule(
        pluginId: googleDrivePluginId,
        typeId: 'googleDrive.${action.id}',
        documentPrimitive: 'googleDrive',
        title: action.titleKey.tr,
        description: action.descriptionKey.tr,
        group: 'Google Drive',
        icon: SimpleIcons.googledrive,
        outputBase: action.outputBase,
        initial: () => GoogleDriveNodeConfig(action: action.id),
        fromDocument: GoogleDriveNodeConfig.fromDocument,
        builder: (node) => GoogleDriveActionWidget(node: node),
      ),
    );
  }
}
