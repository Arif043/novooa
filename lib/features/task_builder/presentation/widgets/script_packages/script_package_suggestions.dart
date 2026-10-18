import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';
import 'package:syscat2/features/script_packages/domain/entities/script_package_environment.dart';

/// Vorschläge aus den Imports: einzelne Pakete übernehmen oder eine fertige
/// Umgebung, die schon alle Imports abdeckt.
class ScriptPackageSuggestions extends StatelessWidget {
  const ScriptPackageSuggestions({
    super.key,
    required this.missing,
    required this.reusable,
    required this.onAdopt,
    required this.onReuse,
  });

  /// Fehlende Pakete, nach Import-Modul (`cv2` → `opencv-python-headless`).
  final Map<String, PythonPackage> missing;
  final ScriptPackageEnvironment? reusable;

  /// Ergänzt die Liste um diese Pakete.
  final ValueChanged<List<PythonPackage>> onAdopt;

  /// Ersetzt die Liste durch die einer vorhandenen Umgebung.
  final ValueChanged<List<PythonPackage>> onReuse;

  @override
  Widget build(BuildContext context) {
    if (missing.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final environment = reusable;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.ui_script_packages_detected.tr(),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in missing.entries)
                ActionChip(
                  avatar: const Icon(Icons.add, size: AppSpacing.md),
                  label: Text(_label(entry.key, entry.value)),
                  onPressed: () => onAdopt([entry.value]),
                ),
              if (missing.length > 1)
                TextButton(
                  onPressed: () => onAdopt(missing.values.toList()),
                  child: Text(LocaleKeys.ui_script_packages_adopt_all.tr()),
                ),
            ],
          ),
          if (environment != null)
            TextButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(
                LocaleKeys.ui_script_packages_reuse.tr(
                  namedArgs: {'packages': environment.packages.join(', ')},
                ),
              ),
              onPressed: () => onReuse(_packagesOf(environment)),
            ),
        ],
      ),
    );
  }

  String _label(String module, PythonPackage package) =>
      module == package.spec ? module : '$module → ${package.spec}';

  List<PythonPackage> _packagesOf(ScriptPackageEnvironment environment) => [
    for (final package in environment.packages) ?PythonPackage.parse(package),
  ];
}
