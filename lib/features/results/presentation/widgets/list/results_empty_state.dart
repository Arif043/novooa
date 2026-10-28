import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Noch kein Lauf: eine Einladung mit genau einer Handlung.
class ResultsEmptyState extends StatelessWidget {
  const ResultsEmptyState({super.key, required this.onOpenTasks});

  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.chart_bar_square,
              size: AppSpacing.xxl,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.results_empty_title.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.results_empty_body.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onOpenTasks,
              icon: const Icon(CupertinoIcons.rectangle_3_offgrid),
              label: Text(LocaleKeys.results_empty_action.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
