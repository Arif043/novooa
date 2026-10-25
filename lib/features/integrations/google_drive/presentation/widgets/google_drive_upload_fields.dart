import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

import '../../domain/google_drive_node_config.dart';
import 'google_drive_action_widget.dart';
import 'google_drive_folder_field.dart';

/// Eingaben von „In Google Drive speichern“: Zielordner, Dateiname, Inhalt.
class GoogleDriveUploadFields extends StatelessWidget {
  const GoogleDriveUploadFields({
    super.key,
    required this.config,
    required this.account,
    required this.update,
  });

  final GoogleDriveNodeConfig config;
  final GoogleAccount? account;
  final GoogleDriveNodeUpdate update;

  @override
  Widget build(BuildContext context) {
    final suggestions = TemplateExpressionScope.suggestionsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoogleDriveFolderField(
          config: config,
          account: account,
          update: update,
          label: LocaleKeys.google_drive_folder.tr(),
          fixedOptions: GoogleDriveFolderField.myDriveOnly(),
        ),
        const SizedBox(height: AppSpacing.sm),
        TemplateExpressionTextField(
          value: config.textParam('fileName'),
          suggestions: suggestions,
          decoration: InputDecoration(
            labelText: LocaleKeys.google_drive_file_name.tr(),
          ),
          onChanged: (value) => update((c) => c.withParam('fileName', value)),
        ),
        const SizedBox(height: AppSpacing.sm),
        TemplateExpressionTextField(
          value: config.textParam('content'),
          suggestions: suggestions,
          minLines: 3,
          maxLines: 9,
          helperText: LocaleKeys.google_drive_content_helper.tr(),
          decoration: InputDecoration(
            labelText: LocaleKeys.google_drive_content.tr(),
          ),
          onChanged: (value) => update((c) => c.withParam('content', value)),
        ),
      ],
    );
  }
}
