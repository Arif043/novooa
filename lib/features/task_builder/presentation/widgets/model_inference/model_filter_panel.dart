import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'model_filter_option_tile.dart';
import 'model_filter_sections.dart';

/// Alle Filtergruppen untereinander und scrollbar — als Spalte neben den Treffern oder als
/// eigene Seite auf schmalen Bildschirmen.
class ModelFilterPanel extends StatelessWidget {
  const ModelFilterPanel({super.key, required this.sections});

  final List<ModelFilterSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        for (final section in sections)
          _SectionView(key: ValueKey(section.title), section: section),
      ],
    );
  }
}

/// Zeigt die häufigsten Optionen; der Rest klappt über „Alle anzeigen“ auf (Hick's Law).
class _SectionView extends StatefulWidget {
  const _SectionView({super.key, required this.section});

  final ModelFilterSection section;

  @override
  State<_SectionView> createState() => _SectionViewState();
}

class _SectionViewState extends State<_SectionView> {
  static const _collapsedCount = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final collapsible = section.options.length > _collapsedCount;
    final visible = _expanded || !collapsible
        ? section.options
        : _collapsed(section.options);
    return Semantics(
      container: true,
      label: LocaleKeys.ui_filter_by_label.tr(
        namedArgs: {'label': section.title},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: section.title),
          for (final option in visible)
            ModelFilterOptionTile(
              option: option,
              multiSelect: section.multiSelect,
            ),
          if (collapsible)
            _ExpandButton(
              expanded: _expanded,
              total: section.options.length,
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
        ],
      ),
    );
  }

  /// Die ersten Optionen, dazu gewählte weiter unten — eine Auswahl verschwindet nie.
  List<ModelFilterOption> _collapsed(List<ModelFilterOption> options) => [
    for (final (index, option) in options.indexed)
      if (index < _collapsedCount || option.selected) option,
  ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({
    required this.expanded,
    required this.total,
    required this.onPressed,
  });

  final bool expanded;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
      ),
      icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      label: Text(
        expanded
            ? LocaleKeys.ui_weniger_anzeigen.tr()
            : LocaleKeys.ui_alle_anzeigen_count.tr(
                namedArgs: {'count': '$total'},
              ),
      ),
    );
  }
}
