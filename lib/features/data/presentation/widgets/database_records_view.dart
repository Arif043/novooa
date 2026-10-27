import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/luminous_page_header.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import 'database_collection_menu.dart';
import 'database_collection_tabs.dart';
import 'database_filter_bar.dart';
import 'database_labels.dart';
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
        const SizedBox(height: AppSpacing.md),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brotkrume statt Zurück-Pfeil: zeigt, wo man ist, und führt zur Übersicht.
        TextButton.icon(
          onPressed: enabled
              ? context.read<DatabaseCubit>().showCollections
              : null,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          icon: const Icon(CupertinoIcons.chevron_left, size: AppSpacing.md),
          label: Text(LocaleKeys.ui_db_page_title.tr()),
        ),
        LuminousPageHeader(
          title: collection.name,
          subtitle: [
            databaseRecordCount(collection.documentCount),
            databaseChangedLabel(
              collection.changedAt,
              DateTime.now(),
              Localizations.localeOf(context).toLanguageTag(),
            ),
          ].join(' · '),
          action: Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
          ),
        ),
      ],
    );
  }
}
