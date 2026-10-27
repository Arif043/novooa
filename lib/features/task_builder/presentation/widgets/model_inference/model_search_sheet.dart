import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/adaptive_sheet.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_search_filter.dart';
import 'model_filter_chips.dart';
import 'model_search_results.dart';
import 'model_search_selection.dart';

/// Durchsucht globalen Katalog und eigene Modelle; liefert das gewählte Modell zurück.
/// Wie die übrigen Auswahl-Sheets: am Desktop als Fenster, sonst als Bottom Sheet.
Future<ModelCatalogEntry?> showModelSearchSheet(
  BuildContext context, {
  SpeechModelDirection? speechDirection,
}) {
  final cubit = context.read<ModelCatalogCubit>();
  return showAdaptiveSheet<ModelCatalogEntry>(
    context: context,
    builder: (_, style) => BlocProvider.value(
      value: cubit,
      child: _ModelSearchSheet(style: style, speechDirection: speechDirection),
    ),
  );
}

class _ModelSearchSheet extends StatefulWidget {
  const _ModelSearchSheet({required this.style, required this.speechDirection});

  final AdaptiveSheetStyle style;
  final SpeechModelDirection? speechDirection;

  @override
  State<_ModelSearchSheet> createState() => _ModelSearchSheetState();
}

class _ModelSearchSheetState extends State<_ModelSearchSheet> {
  /// Standardhöhe des Fenster-Sheets; bei kleinen Fenstern begrenzt es die Karte.
  static const _windowSheetHeight = 600.0;

  String _query = '';
  ModelSearchSelection _selection = const ModelSearchSelection();

  @override
  Widget build(BuildContext context) {
    final isWindow = widget.style.isWindow;
    final filter = ModelSearchFilter(
      languageTag: Localizations.localeOf(context).toLanguageTag(),
      speechDirection: widget.speechDirection,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(leading: isWindow ? null : const _CancelButton()),
        const Divider(height: 1),
        Expanded(child: _searchBody(filter)),
        if (isWindow) ...[
          const Divider(height: 1),
          SheetFooter(
            onCancel: () => Navigator.of(context).pop(),
            cancelLabel: LocaleKeys.ui_abbrechen.tr(),
          ),
        ],
      ],
    );
    // Im Bottom Sheet relativ zum verfügbaren Platz (ohne Greifer), im Fenster feste Höhe.
    return isWindow
        ? SizedBox(height: _windowSheetHeight, child: content)
        : FractionallySizedBox(heightFactor: 0.85, child: content);
  }

  Widget _searchBody(ModelSearchFilter filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: LocaleKeys
                  .ui_nach_name_beschreibung_oder_schlagwort_suchen
                  .tr(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: BlocBuilder<ModelCatalogCubit, ModelCatalogState>(
              builder: (context, state) => _FilteredResults(
                state: state,
                filter: filter,
                query: _query,
                selection: _selection,
                onSelectionChanged: (value) =>
                    setState(() => _selection = value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.leading});

  /// Nur im Bottom Sheet; das Fenster-Sheet führt Abbrechen in der Fußzeile.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SizedBox(
        height: kToolbarHeight,
        child: NavigationToolbar(
          leading: leading,
          middle: Text(
            LocaleKeys.ui_modell_auswaehlen.tr(),
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(LocaleKeys.ui_abbrechen.tr()),
    );
  }
}

class _FilteredResults extends StatelessWidget {
  const _FilteredResults({
    required this.state,
    required this.filter,
    required this.query,
    required this.selection,
    required this.onSelectionChanged,
  });

  final ModelCatalogState state;
  final ModelSearchFilter filter;
  final String query;
  final ModelSearchSelection selection;
  final ValueChanged<ModelSearchSelection> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final models = state.selectableEntries;
    final filter = this.filter.withVocabulary(state.tagVocabulary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModelFilterChips(
          facets: filter.facets(models, query, selection),
          selection: selection,
          showTasks: filter.fixedTask == null,
          topicLabel: (topic) =>
              state.tagVocabulary.labelFor(topic, filter.languageTag),
          onChanged: onSelectionChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ModelSearchResults(
            state: state,
            models: filter.apply(models, query, selection),
            hasQuery: query.trim().isNotEmpty,
            onResetFilters: selection.isActive
                ? () => onSelectionChanged(const ModelSearchSelection())
                : null,
          ),
        ),
      ],
    );
  }
}
