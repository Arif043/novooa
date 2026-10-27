import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_filter_page.dart';
import 'model_filter_panel.dart';
import 'model_filter_sections.dart';
import 'model_search_filter.dart';
import 'model_search_panes.dart';
import 'model_search_selection.dart';

/// Ab dieser Breite steht die Filterspalte neben den Treffern; darunter liegen die Filter auf
/// einer eigenen Seite. Entscheidet die verfügbare Breite, nicht die Plattform.
const modelSearchSidebarMinWidth = 640.0;

/// Suche, Filter und Treffer der Modellsuche; [filter] kennt bereits das Tag-Vokabular.
class ModelSearchLayout extends StatefulWidget {
  const ModelSearchLayout({
    super.key,
    required this.state,
    required this.filter,
    required this.queryController,
    required this.selection,
    required this.onSelectionChanged,
  });

  final ModelCatalogState state;
  final ModelSearchFilter filter;
  final TextEditingController queryController;
  final ModelSearchSelection selection;
  final ValueChanged<ModelSearchSelection> onSelectionChanged;

  @override
  State<ModelSearchLayout> createState() => _ModelSearchLayoutState();
}

class _ModelSearchLayoutState extends State<ModelSearchLayout> {
  bool _showsFilterPage = false;

  /// Nach der Filterseite nicht erneut fokussieren — sonst öffnet mobil die Tastatur.
  bool _hasShownFilterPage = false;

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final activeFilters = [
      for (final section in sections) ...section.selectedOptions,
    ];
    final query = widget.queryController.text;
    final matches = ModelSearchMatches(
      state: widget.state,
      models: widget.filter.apply(_models, query, widget.selection),
      hasQuery: query.trim().isNotEmpty,
      activeFilters: activeFilters,
      onResetFilters: _reset,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= modelSearchSidebarMinWidth) {
          return _wide(constraints.maxWidth, sections, matches);
        }
        if (_showsFilterPage) {
          return _filterPage(sections, matches.models.length);
        }
        return _narrow(sections, activeFilters.length, matches);
      },
    );
  }

  List<ModelFilterSection> _sections() => ModelFilterSectionsBuilder(
    facets: widget.filter.facets(
      _models,
      widget.queryController.text,
      widget.selection,
    ),
    selection: widget.selection,
    showTasks: widget.filter.fixedTask == null,
    topicLabel: (topic) =>
        widget.state.tagVocabulary.labelFor(topic, widget.filter.languageTag),
    onChanged: widget.onSelectionChanged,
  ).build();

  List<ModelCatalogEntry> get _models => widget.state.selectableEntries;

  void _reset() => widget.onSelectionChanged(const ModelSearchSelection());

  void _toggleFilterPage(bool visible) => setState(() {
    _showsFilterPage = visible;
    _hasShownFilterPage = true;
  });

  Widget _wide(
    double width,
    List<ModelFilterSection> sections,
    ModelSearchMatches matches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _padded(
          ModelSearchField(controller: widget.queryController, autofocus: true),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sections.isNotEmpty) ...[
                SizedBox(
                  width: (width * 0.3).clamp(200.0, 280.0),
                  child: ModelFilterPanel(sections: sections),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: _padded(matches)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrow(
    List<ModelFilterSection> sections,
    int active,
    ModelSearchMatches matches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _padded(
          Row(
            children: [
              Expanded(
                child: ModelSearchField(
                  controller: widget.queryController,
                  autofocus: !_hasShownFilterPage,
                ),
              ),
              if (sections.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                ModelFilterButton(
                  activeCount: active,
                  onPressed: () => _toggleFilterPage(true),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _padded(matches)),
      ],
    );
  }

  Widget _filterPage(List<ModelFilterSection> sections, int matchCount) {
    return ModelFilterPage(
      sections: sections,
      matchCount: matchCount,
      onDone: () => _toggleFilterPage(false),
      onReset: widget.selection.isActive ? _reset : null,
    );
  }

  Widget _padded(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      0,
    ),
    child: child,
  );
}
