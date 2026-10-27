import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';

/// Mitarbeiter ohne Einträge: zentrierte Einladung mit genau einer Handlung. Statt eines
/// Symbols winkt Noovi — Mitarbeiter sind Noovis.
class EmployeesEmptyState extends StatelessWidget {
  const EmployeesEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

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
                const NooviImage(
                  pose: NooviPose.wave,
                  size: AppSpacing.section + AppSpacing.xl,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  LocaleKeys.ui_employees_empty_title.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  LocaleKeys.ui_employees_empty_body.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(CupertinoIcons.add),
                  label: Text(LocaleKeys.ui_employees_create.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
