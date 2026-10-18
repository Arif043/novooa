import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';
import 'package:syscat2/features/script_packages/domain/entities/script_package_environment.dart';
import 'package:syscat2/features/script_packages/domain/services/import_package_names.dart';
import 'package:syscat2/features/script_packages/domain/services/python_import_scanner.dart';
import 'package:syscat2/features/script_packages/presentation/cubits/script_packages_cubit.dart';
import 'package:syscat2/features/script_packages/presentation/cubits/script_packages_state.dart';

import 'script_package_editor.dart';
import 'script_package_status_row.dart';
import 'script_package_suggestions.dart';

/// Python-Pakete eines Script-Bausteins: eintragen, aus Imports übernehmen,
/// eine vorhandene Umgebung wiederverwenden und per Klick installieren.
class ScriptPackagesSection extends StatelessWidget {
  const ScriptPackagesSection({
    super.key,
    required this.script,
    required this.packages,
    required this.onChanged,
  });

  final String script;
  final List<PythonPackage> packages;
  final ValueChanged<List<PythonPackage>> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScriptPackagesCubit, ScriptPackagesState>(
      builder: (context, state) {
        final missing = _missingPackages();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.ui_script_packages_title.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            ScriptPackageEditor(packages: packages, onChanged: onChanged),
            ScriptPackageSuggestions(
              missing: missing,
              reusable: _reusable(state, missing),
              onAdopt: (adopted) => onChanged([...packages, ...adopted]),
              onReuse: onChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Status(state: state, packages: packages),
          ],
        );
      },
    );
  }

  /// Importierte Module, deren Paket noch nicht eingetragen ist.
  Map<String, PythonPackage> _missingPackages() {
    final listed = {for (final package in packages) package.name};
    return {
      for (final module in const PythonImportScanner()(script))
        if (PythonPackage.parse(const ImportPackageNames().packageFor(module))
            case final package? when !listed.contains(package.name))
          module: package,
    };
  }

  /// Nur solange noch nichts eingetragen ist: Eine fertige Umgebung, die alle
  /// Imports abdeckt, macht eine zweite Installation überflüssig.
  ScriptPackageEnvironment? _reusable(
    ScriptPackagesState state,
    Map<String, PythonPackage> missing,
  ) {
    if (packages.isNotEmpty || missing.isEmpty) return null;
    final covering = state.readyCovering({
      for (final package in missing.values) package.name,
    });
    return covering.isEmpty ? null : covering.first;
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.state, required this.packages});

  final ScriptPackagesState state;
  final List<PythonPackage> packages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (packages.isEmpty) {
      return Text(
        LocaleKeys.ui_script_packages_empty.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return switch (state.status) {
      ScriptPackagesStatus.loading => const LinearProgressIndicator(),
      ScriptPackagesStatus.failure => Text(
        LocaleKeys.ui_script_packages_status_unavailable.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      ScriptPackagesStatus.ready => ScriptPackageStatusRow(
        environment: state.environmentFor(packages),
        onInstall: () => context.read<ScriptPackagesCubit>().install(packages),
      ),
    };
  }
}
