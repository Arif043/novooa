import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_import_preview.dart';

/// Was der Import übernehmen würde: Anzahl, Felder, umbenannte Spalten, Beispiele, Probleme.
class DatabaseImportPreviewView extends StatelessWidget {
  const DatabaseImportPreviewView({
    super.key,
    required this.preview,
    required this.fileName,
  });

  final DataImportPreview preview;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.ui_db_import_summary.tr(
              namedArgs: {'count': '${preview.count}', 'file': fileName},
            ),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview.count == 0
                ? LocaleKeys.ui_db_import_empty.tr()
                : LocaleKeys.ui_db_import_append_hint.tr(),
            style: theme.textTheme.bodySmall,
          ),
          if (preview.issues.isNotEmpty) _Issues(issues: preview.issues),
          if (preview.fields.isNotEmpty)
            _Section(
              title: LocaleKeys.ui_db_import_fields.tr(),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final field in preview.fields)
                    Chip(
                      label: Text(field),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          if (preview.renamedFields.isNotEmpty)
            _Section(
              title: LocaleKeys.ui_db_import_renamed.tr(),
              child: _Lines([
                for (final rename in preview.renamedFields)
                  '${rename.from} → ${rename.to}',
              ]),
            ),
          if (preview.sample.isNotEmpty)
            _Section(
              title: LocaleKeys.ui_db_import_sample.tr(),
              child: _Lines([
                for (final row in preview.sample)
                  row.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Issues extends StatelessWidget {
  const _Issues({required this.issues});

  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Section(
      title: LocaleKeys.ui_db_import_issues.tr(),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.error),
        child: _Lines([...issues, LocaleKeys.ui_db_import_issues_hint.tr()]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines(this.lines);

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              line,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
