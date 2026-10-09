import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
          decoration: InputDecoration(labelText: LocaleKeys.ui_dateiname.tr()),
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
