import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/workspace_export_cubit.dart';
import '../cubits/workspace_import_cubit.dart';
import 'workspace_export_section.dart';
import 'workspace_import_section.dart';

/// Tab „Import/Export“ in den Runtime-Einstellungen (nur Standalone).
class ImportExportSettingsTab extends StatelessWidget {
  const ImportExportSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<WorkspaceExportCubit>()),
        BlocProvider(create: (_) => serviceLocator<WorkspaceImportCubit>()),
      ],
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          WorkspaceExportSection(),
          SizedBox(height: AppSpacing.lg),
          WorkspaceImportSection(),
        ],
      ),
    );
  }
}
