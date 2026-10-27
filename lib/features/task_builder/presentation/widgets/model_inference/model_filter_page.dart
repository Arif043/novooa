import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'model_filter_panel.dart';
import 'model_filter_sections.dart';

/// Filter auf schmalen Bildschirmen als eigene Seite im Sheet; zurück zu den Treffern über
/// „Zurück“ oder die Schaltfläche mit der Trefferzahl.
class ModelFilterPage extends StatelessWidget {
  const ModelFilterPage({
    super.key,
    required this.sections,
    required this.matchCount,
    required this.onDone,
    this.onReset,
  });

  final List<ModelFilterSection> sections;
  final int matchCount;
  final VoidCallback onDone;

  /// Gesetzt, wenn Filter aktiv sind.
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.chevron_left),
                label: Text(LocaleKeys.ui_zurueck.tr()),
              ),
              const Spacer(),
              if (onReset case final reset?)
                TextButton(
                  onPressed: reset,
                  child: Text(LocaleKeys.ui_filter_zuruecksetzen.tr()),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: ModelFilterPanel(sections: sections)),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: onDone,
            child: Text(
              LocaleKeys.ui_treffer_anzeigen_count.tr(
                namedArgs: {'count': '$matchCount'},
              ),
            ),
          ),
        ),
      ],
    );
  }
}
