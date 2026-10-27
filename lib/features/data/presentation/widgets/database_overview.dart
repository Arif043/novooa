import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import 'database_collection_actions.dart';
import 'database_collection_menu.dart';
import 'database_sheet.dart';
import 'database_states.dart';

/// Alle Sammlungen als Blatt; eine Zeile öffnet die Sammlung, das Menü verwaltet sie.
class DatabaseOverview extends StatelessWidget {
  const DatabaseOverview({super.key, required this.state, required this.busy});

  final DatabaseState state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final createButton = FilledButton.icon(
      onPressed: busy ? null : () => createDatabaseCollection(context),
      icon: const Icon(CupertinoIcons.add, size: AppSpacing.gutter),
      label: Text(LocaleKeys.ui_db_collection_create.tr()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Text(
              LocaleKeys.ui_db_collections_title.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.collections.isNotEmpty) createButton,
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Expanded(child: _content(context, createButton)),
      ],
    );
  }

  Widget _content(BuildContext context, Widget createButton) {
    if (state.collections.isEmpty) {
      return DatabaseEmptyState(
        title: LocaleKeys.ui_db_empty_overview_title.tr(),
        message: LocaleKeys.ui_db_empty_overview_body.tr(),
        action: createButton,
      );
    }
    final cubit = context.read<DatabaseCubit>();
    return DatabaseSheet(
      columns: [
        LocaleKeys.ui_db_column_collection.tr(),
        LocaleKeys.ui_db_column_records.tr(),
      ],
      rows: [
        for (final collection in state.collections)
          [collection.name, '${collection.documentCount}'],
      ],
      enabled: !busy,
      onOpen: (index) => cubit.openCollection(state.collections[index]),
      trailingBuilder: (_, index) => DatabaseCollectionMenu(
        collection: state.collections[index],
        enabled: !busy,
      ),
    );
  }
}
