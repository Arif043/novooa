import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Fähigkeiten ohne Einträge: zentrierte Einladung mit genau einer Handlung, wie beim Zeitplan.
class SkillsEmptyState extends StatelessWidget {
  const SkillsEmptyState({super.key, required this.onImport});

  final VoidCallback onImport;

  /// Lesbare Zeilenlänge der Erklärung, wie bei den übrigen leeren Zuständen.
  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: AppSpacing.xxl,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  LocaleKeys.ui_skills_empty_title.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  LocaleKeys.ui_skills_empty_body.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(CupertinoIcons.arrow_down_to_line),
                  label: Text(LocaleKeys.ui_skills_empty_import.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
