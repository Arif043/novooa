import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/upload_file_input.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import 'create_folder_dialog.dart';

class FilesActionBar extends StatelessWidget {
  const FilesActionBar({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: state.isCreatingFolder
              ? null
              : () => _createFolder(context),
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Verzeichnis'),
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
    final input = await _pickFile();
    if (!context.mounted || input == null) return;
    await context.read<FilesCubit>().upload(input);
  }

  Future<UploadFileInput?> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return UploadFileInput(
      name: file.name,
      bytes: Uint8List.fromList(bytes),
      sizeBytes: file.size,
      contentType: _contentTypeFor(file.extension),
    );
  }

  String _contentTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'json' => 'application/json',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
