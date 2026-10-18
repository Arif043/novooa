import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/machine_learning/presentation/widgets/model_size_label.dart';
import 'package:syscat2/features/script_packages/domain/entities/script_package_environment.dart';

/// Stand der Umgebung für die Paketliste des Bausteins: nicht installiert,
/// wird installiert, installiert oder gescheitert — mit der passenden Aktion.
class ScriptPackageStatusRow extends StatelessWidget {
  const ScriptPackageStatusRow({
    super.key,
    required this.environment,
    required this.onInstall,
  });

  /// `null`: Für diese Liste gibt es noch keine Umgebung.
  final ScriptPackageEnvironment? environment;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = environment;
    return switch (current?.state) {
      null => _StatusLine(
        icon: Icon(Icons.download_outlined, color: colors.onSurfaceVariant),
        text: LocaleKeys.ui_script_packages_not_installed.tr(),
        action: FilledButton.tonal(
          onPressed: onInstall,
          child: Text(LocaleKeys.ui_script_packages_install.tr()),
        ),
      ),
      ScriptPackageEnvironmentState.installing => _StatusLine(
        icon: const SizedBox.square(
          dimension: AppSpacing.md,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        text: LocaleKeys.ui_script_packages_installing.tr(),
      ),
      ScriptPackageEnvironmentState.ready => _StatusLine(
        icon: Icon(Icons.check_circle_outline, color: colors.primary),
        text: LocaleKeys.ui_script_packages_ready.tr(
          namedArgs: {'size': modelSizeLabel(current!.sizeBytes ?? 0)},
        ),
      ),
      ScriptPackageEnvironmentState.failed => _StatusLine(
        icon: Icon(Icons.error_outline, color: colors.error),
        text: _failureText(current!.problem),
        detail: current.detail,
        action: TextButton(
          onPressed: onInstall,
          child: Text(LocaleKeys.ui_script_packages_retry.tr()),
        ),
      ),
    };
  }

  String _failureText(ScriptPackageInstallProblem? problem) {
    return switch (problem ?? ScriptPackageInstallProblem.failed) {
      .notFound => LocaleKeys.ui_script_packages_failed_notFound.tr(),
      .noWheel => LocaleKeys.ui_script_packages_failed_noWheel.tr(),
      .tooLarge => LocaleKeys.ui_script_packages_failed_tooLarge.tr(),
      .notLoadable => LocaleKeys.ui_script_packages_failed_notLoadable.tr(),
      .failed => LocaleKeys.ui_script_packages_failed_failed.tr(),
    };
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.text,
    this.detail,
    this.action,
  });

  final Widget icon;
  final String text;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconTheme.merge(
            data: const IconThemeData(size: AppSpacing.md),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: style),
                if (detail != null && detail!.isNotEmpty)
                  SelectableText(detail!, style: style, maxLines: 4),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
