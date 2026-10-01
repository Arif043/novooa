import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_folder_picker.dart';

class NewWriteFileForm extends StatelessWidget {
  const NewWriteFileForm({
    super.key,
    required this.nameController,
    required this.selectedFolderId,
    required this.onFolderSelected,
  });

  final TextEditingController nameController;
  final String? selectedFolderId;
  final ValueChanged<String?> onFolderSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Dateiname'),
        ),
        const SizedBox(height: AppSpacing.lg),
        WriteFileFolderPicker(
          selectedFolderId: selectedFolderId,
          onSelected: onFolderSelected,
        ),
      ],
    );
  }
}
