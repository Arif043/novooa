import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Laden oder Fehler unter dem Seitenkopf; der Fehler bietet „Erneut versuchen“.
class SkillsStatusPlaceholder extends StatelessWidget {
  const SkillsStatusPlaceholder({
    super.key,
    required this.loading,
    required this.onRetry,
    this.message,
  });

  final bool loading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CupertinoActivityIndicator());
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: AppSpacing.xxl,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message ?? LocaleKeys.ui_skills_load_failed.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(LocaleKeys.ui_erneut_versuchen.tr()),
          ),
        ],
      ),
    );
  }
}
