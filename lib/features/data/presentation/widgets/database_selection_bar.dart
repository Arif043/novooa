import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import 'database_collection_actions.dart';

/// Ersetzt den Hinweis über dem Blatt, sobald Datensätze ausgewählt sind.
class DatabaseSelectionBar extends StatelessWidget {
  const DatabaseSelectionBar({
    super.key,
    required this.state,
    required this.busy,
  });

  final DatabaseState state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = state.selectedIds.length;
    if (count == 0) {
      return Text(
        LocaleKeys.ui_db_records_hint.tr(
          namedArgs: {'count': '${state.records.length}'},
        ),
        style: theme.textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            LocaleKeys.ui_db_selected_count.tr(namedArgs: {'count': '$count'}),
            style: theme.textTheme.titleSmall,
          ),
        ),
        TextButton.icon(
          onPressed: busy ? null : () => deleteSelectedDatabaseRecords(context),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          icon: const Icon(
            CupertinoIcons.trash,
            size: AppSpacing.md + AppSpacing.xs,
          ),
          label: Text(LocaleKeys.ui_loeschen.tr()),
        ),
        TextButton(
          onPressed: context.read<DatabaseCubit>().clearSelection,
          child: Text(LocaleKeys.ui_db_selection_clear.tr()),
        ),
      ],
    );
  }
}
