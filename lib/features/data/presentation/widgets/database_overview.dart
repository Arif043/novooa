import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/layout/page_insets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/luminous_page_header.dart';
import '../../domain/entities/data_collection.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import 'database_collection_actions.dart';
import 'database_collection_card.dart';
import 'database_labels.dart';
import 'database_states.dart';

/// Alle Sammlungen im Seitenstil des Zeitplans: Kopf mit Zusammenfassung, Suche, Karten.
class DatabaseOverview extends StatefulWidget {
  const DatabaseOverview({super.key, required this.state, required this.busy});

  final DatabaseState state;
  final bool busy;

  @override
  State<DatabaseOverview> createState() => _DatabaseOverviewState();
}

class _DatabaseOverviewState extends State<DatabaseOverview> {
  String _query = '';

  List<DataCollection> get _collections => widget.state.collections;

  @override
  Widget build(BuildContext context) {
    if (_collections.isEmpty) {
      return DatabaseEmptyState(
        title: LocaleKeys.ui_db_empty_overview_title.tr(),
        message: LocaleKeys.ui_db_empty_overview_body.tr(),
        action: _createButton(context),
      );
    }
    final matches = _collections.where(_matches).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = PageInsets.forWidth(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            _padded(insets, AppSpacing.xl, _header(context)),
            if (_collections.length > 1)
              _padded(insets, 0, _SearchField(onChanged: _search)),
            if (matches.isEmpty)
              _padded(insets, 0, _NoMatch(query: _query))
            else
              _list(insets, matches),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final records = _collections.fold(
      0,
      (sum, item) => sum + item.documentCount,
    );
    return LuminousPageHeader(
      title: LocaleKeys.ui_db_page_title.tr(),
      subtitle: LocaleKeys.ui_db_page_subtitle.tr(),
      summary:
          '${databaseCollectionCount(_collections.length)} · '
          '${databaseRecordCount(records)}',
      action: _createButton(context),
    );
  }

  Widget _createButton(BuildContext context) => FilledButton.icon(
    onPressed: widget.busy ? null : () => createDatabaseCollection(context),
    icon: const Icon(CupertinoIcons.add, size: AppSpacing.gutter),
    label: Text(LocaleKeys.ui_db_collection_create.tr()),
  );

  Widget _list(PageInsets insets, List<DataCollection> matches) {
    final now = DateTime.now();
    final cubit = context.read<DatabaseCubit>();
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        insets.inset,
        0,
        insets.inset,
        AppSpacing.pageDesktop,
      ),
      sliver: SliverList.separated(
        itemCount: matches.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        itemBuilder: (_, index) => DatabaseCollectionCard(
          key: ValueKey(matches[index].name),
          collection: matches[index],
          now: now,
          enabled: !widget.busy,
          onOpen: () => cubit.openCollection(matches[index]),
        ),
      ),
    );
  }

  Widget _padded(PageInsets insets, double top, Widget child) => SliverPadding(
    padding: EdgeInsets.fromLTRB(
      insets.inset,
      top,
      insets.inset,
      AppSpacing.lg,
    ),
    sliver: SliverToBoxAdapter(child: child),
  );

  /// Sucht in Namen und Feldnamen, ohne Groß- und Kleinschreibung.
  bool _matches(DataCollection collection) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      collection.name,
      ...collection.fields,
    ].any((text) => text.toLowerCase().contains(query));
  }

  void _search(String value) => setState(() => _query = value);
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      prefixIcon: const Icon(CupertinoIcons.search),
      hintText: LocaleKeys.ui_db_search_collections.tr(),
    ),
  );
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.ui_db_no_collection_match.tr(namedArgs: {'query': query.trim()}),
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
