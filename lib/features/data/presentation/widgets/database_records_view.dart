import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import 'database_collection_menu.dart';
import 'database_collection_tabs.dart';
import 'database_filter_bar.dart';
import 'database_record_actions.dart';
import 'database_records_sheet.dart';
import 'database_selection_bar.dart';

/// Eine geöffnete Sammlung: Werkzeugleiste, Auswahl, Suche und Filter, Blatt, Reiter.
class DatabaseRecordsView extends StatelessWidget {
  const DatabaseRecordsView({
    super.key,
    required this.state,
    required this.busy,
  });

  final DatabaseState state;

  /// Läuft gerade eine Änderung — Datensatz oder Sammlung —, sind Aktionen gesperrt.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && !state.isMutating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(state: state, enabled: enabled),
        const SizedBox(height: AppSpacing.sm),
        DatabaseSelectionBar(state: state, busy: !enabled),
        const SizedBox(height: AppSpacing.gutter),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .28,
          ),
          child: SingleChildScrollView(child: DatabaseFilterBar(state: state)),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: DatabaseRecordsSheet(state: state, enabled: enabled),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        DatabaseCollectionTabs(state: state, enabled: enabled),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.state, required this.enabled});

  final DatabaseState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final collection = state.collection!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: LocaleKeys.ui_db_collections_title.tr(),
          onPressed: enabled
              ? context.read<DatabaseCubit>().showCollections
              : null,
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
        Text(collection.name, style: Theme.of(context).textTheme.titleLarge),
        FilledButton.icon(
          onPressed: enabled ? () => editDatabaseRecord(context) : null,
          icon: const Icon(CupertinoIcons.add, size: AppSpacing.gutter),
          label: Text(LocaleKeys.ui_db_record_create.tr()),
        ),
        DatabaseCollectionMenu(
          collection: collection,
          withTransfer: true,
          enabled: enabled,
        ),
      ],
    );
  }
}
