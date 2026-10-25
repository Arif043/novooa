import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';

import '../../domain/google_drive_node_config.dart';
import 'google_drive_action_widget.dart';

/// Ordnerauswahl einer Drive-Aktion: feste Einträge (z. B. „Meine Ablage“)
/// und die freigegebenen Ordner des Kontos. Schreibt `folderId`.
class GoogleDriveFolderField extends StatelessWidget {
  const GoogleDriveFolderField({
    super.key,
    required this.config,
    required this.account,
    required this.update,
    required this.label,
    required this.fixedOptions,
  });

  final GoogleDriveNodeConfig config;
  final GoogleAccount? account;
  final GoogleDriveNodeUpdate update;
  final String label;

  /// Wert → Anzeigename; der Leerstring gilt, solange nichts gewählt ist.
  final Map<String, String> fixedOptions;

  /// Für „Speichern“: ohne Ordner landet die Datei in „Meine Ablage“.
  static Map<String, String> myDriveOnly() => {
    '': LocaleKeys.google_drive_my_drive.tr(),
  };

  /// Für „Suchen“: ohne Ordner sucht Drive überall; `root` ist „Meine Ablage“.
  static Map<String, String> everywhereOrMyDrive() => {
    '': LocaleKeys.google_drive_search_everywhere.tr(),
    'root': LocaleKeys.google_drive_my_drive.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final folders = account?.sharedFolders ?? const [];
    final selected = config.textParam('folderId');
    final known =
        fixedOptions.containsKey(selected) ||
        folders.any((f) => f.id == selected);
    return DropdownButtonFormField<String>(
      key: ValueKey('drive-folder-$selected-${folders.length}'),
      initialValue: known ? selected : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in fixedOptions.entries)
          DropdownMenuItem(value: option.key, child: Text(option.value)),
        for (final folder in folders)
          DropdownMenuItem(
            value: folder.id,
            child: Text(folder.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) => update((c) => c.withParam('folderId', id)),
    );
  }
}
