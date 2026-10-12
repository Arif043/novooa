import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_cubit.dart';
import 'create_folder_dialog.dart';
import 'file_upload_picker.dart';

/// Erster Eindruck von „Dateien“ ohne Inhalt: eine zentrierte Einladung mit
/// einer Haupthandlung, analog zur Wissensbasis und zum Zeitplan.
class FilesInitialState extends StatelessWidget {
  const FilesInitialState({super.key, required this.isUploading});

  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.folder,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  LocaleKeys.ui_files_initial_title.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  LocaleKeys.ui_files_initial_body.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: isUploading ? null : () => _upload(context),
                  icon: const Icon(CupertinoIcons.cloud_upload),
                  label: Text(LocaleKeys.ui_files_initial_upload.tr()),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => _createFolder(context),
                  child: Text(LocaleKeys.ui_files_initial_folder.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _upload(BuildContext context) async {
    final input = await pickUploadFile();
    if (!context.mounted || input == null) return;
    await context.read<FilesCubit>().upload(input);
  }

  Future<void> _createFolder(BuildContext context) async {
    final name = await CreateFolderDialog.show(context);
    if (!context.mounted || name == null) return;
    await context.read<FilesCubit>().createFolder(name);
  }
}
