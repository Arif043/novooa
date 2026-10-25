import 'package:easy_localization/easy_localization.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';

import 'domain/google_drive_actions.dart';
import 'domain/google_drive_node_config.dart';
import 'presentation/widgets/google_drive_action_widget.dart';

/// Meldet die Drive-Bausteine an: je Aktion ein Eintrag in der Palette, alle
/// teilen sich Konfiguration und Formular.
void registerGoogleDrivePlugin() {
  for (final action in GoogleDriveActions.all) {
    PluginNodeModules.register(
      PluginNodeModule(
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
