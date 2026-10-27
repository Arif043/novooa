import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/luminous_card.dart';
import '../../domain/entities/data_collection.dart';
import 'database_collection_menu.dart';
import 'database_labels.dart';

/// Eine Sammlung als Karte wie im Zeitplan: Symbol, Name, Feldvorschau; unten Anzahl, letzte
/// Änderung und das Menü. Antippen öffnet das Blatt.
class DatabaseCollectionCard extends StatelessWidget {
  const DatabaseCollectionCard({
    super.key,
    required this.collection,
    required this.onOpen,
    required this.now,
    this.enabled = true,
  });

  final DataCollection collection;
  final VoidCallback onOpen;

  /// Bezugszeit für „geändert vor …“; von außen, damit eine Liste einheitlich rechnet.
  final DateTime now;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      databaseRecordCount(collection.documentCount),
      databaseChangedLabel(
        collection.changedAt,
        now,
        Localizations.localeOf(context).toLanguageTag(),
      ),
    ].join(' · ');
    return LuminousCard(
      onTap: enabled ? onOpen : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuminousCardHeading(
            leading: const LuminousIconBadge(icon: CupertinoIcons.table),
            title: collection.name,
            subtitle: databaseFieldPreview(collection.fields),
            subtitleMaxLines: 1,
          ),
          const SizedBox(height: AppSpacing.gutter),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(details, style: theme.textTheme.bodySmall)),
              DatabaseCollectionMenu(
                collection: collection,
                withTransfer: true,
                enabled: enabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
