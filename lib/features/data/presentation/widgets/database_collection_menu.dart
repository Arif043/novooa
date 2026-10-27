import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/data_collection.dart';
import 'database_collection_actions.dart';

/// Seltene Aktionen einer Sammlung hinter einem Menüknopf (Hick's Law). Im Blatt kommen
/// Import und Export dazu.
class DatabaseCollectionMenu extends StatelessWidget {
  const DatabaseCollectionMenu({
    super.key,
    required this.collection,
    this.withTransfer = false,
    this.enabled = true,
  });

  final DataCollection collection;
  final bool withTransfer;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DatabaseCollectionAction>(
      enabled: enabled,
      tooltip: LocaleKeys.ui_db_collection_actions.tr(
        namedArgs: {'name': collection.name},
      ),
      icon: const Icon(CupertinoIcons.ellipsis_circle),
      onSelected: (action) =>
          runDatabaseCollectionAction(context, action, collection),
      itemBuilder: (context) => [
        if (withTransfer) ...[
          _item(
            DatabaseCollectionAction.import,
            CupertinoIcons.arrow_down_doc,
            LocaleKeys.ui_db_import,
          ),
          _item(
            DatabaseCollectionAction.exportCsv,
            CupertinoIcons.arrow_up_doc,
            LocaleKeys.ui_db_export_csv,
          ),
          _item(
            DatabaseCollectionAction.exportJson,
            CupertinoIcons.arrow_up_doc,
            LocaleKeys.ui_db_export_json,
          ),
          const PopupMenuDivider(),
        ],
        _item(
          DatabaseCollectionAction.rename,
          CupertinoIcons.pencil,
          LocaleKeys.ui_db_collection_rename,
        ),
        _item(
          DatabaseCollectionAction.clear,
          CupertinoIcons.clear,
          LocaleKeys.ui_db_collection_clear,
        ),
        _item(
          DatabaseCollectionAction.delete,
          CupertinoIcons.trash,
          LocaleKeys.ui_db_collection_delete,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  PopupMenuItem<DatabaseCollectionAction> _item(
    DatabaseCollectionAction action,
    IconData icon,
    String labelKey, {
    Color? color,
  }) => PopupMenuItem(
    value: action,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(labelKey.tr(), style: TextStyle(color: color)),
    ),
  );
}
