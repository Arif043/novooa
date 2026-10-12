import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import 'create_folder_dialog.dart';
import 'file_upload_picker.dart';

class FilesActionBar extends StatelessWidget {
  const FilesActionBar({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: state.isCreatingFolder
              ? null
              : () => _createFolder(context),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: Text(
            state.isCreatingFolder ? 'Wird erstellt …' : 'Neuer Ordner',
          ),
        ),
        FilledButton.icon(
          onPressed: state.isUploading ? null : () => _pickAndUpload(context),
          icon: state.isUploading
              ? const _ButtonSpinner()
              : const Icon(Icons.upload_file_outlined),
          label: Text(
            state.isUploading ? 'Wird hochgeladen' : 'Datei hochladen',
          ),
        ),
      ],
    );
  }

  Future<void> _createFolder(BuildContext context) async {
    final name = await CreateFolderDialog.show(context);
    if (!context.mounted || name == null) return;
    await context.read<FilesCubit>().createFolder(name);
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final input = await pickUploadFile();
    if (!context.mounted || input == null) return;
    await context.read<FilesCubit>().upload(input);
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: AppSpacing.md,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
