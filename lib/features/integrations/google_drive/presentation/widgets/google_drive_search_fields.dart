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

/// Eingaben von „In Google Drive suchen“: Ordner, Name, Höchstanzahl.
class GoogleDriveSearchFields extends StatelessWidget {
  const GoogleDriveSearchFields({
    super.key,
    required this.config,
    required this.account,
    required this.update,
  });

  /// Wie im Backend (`search-action.ts`).
  static const limitMax = 100;

  final GoogleDriveNodeConfig config;
  final GoogleAccount? account;
  final GoogleDriveNodeUpdate update;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoogleDriveFolderField(
          config: config,
          account: account,
          update: update,
          label: LocaleKeys.google_drive_search_folder.tr(),
          fixedOptions: GoogleDriveFolderField.everywhereOrMyDrive(),
        ),
        const SizedBox(height: AppSpacing.sm),
        TemplateExpressionTextField(
          value: config.textParam('name'),
          suggestions: TemplateExpressionScope.suggestionsOf(context),
          decoration: InputDecoration(
            labelText: LocaleKeys.google_drive_search_name.tr(),
          ),
          onChanged: (value) => update((c) => c.withParam('name', value)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LimitField(config: config, update: update),
        const SizedBox(height: AppSpacing.sm),
        Text(
          LocaleKeys.google_drive_search_helper.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LimitField extends StatelessWidget {
  const _LimitField({required this.config, required this.update});

  final GoogleDriveNodeConfig config;
  final GoogleDriveNodeUpdate update;

  @override
  Widget build(BuildContext context) {
    final limit = config.params['limit'];
    return TextFormField(
      initialValue: limit is int ? '$limit' : '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: LocaleKeys.google_drive_search_limit.tr(),
        helperText: LocaleKeys.google_drive_search_limit_helper.tr(),
      ),
      onChanged: (text) {
        final number = int.tryParse(text.trim());
        if (text.trim().isNotEmpty && number == null) return;
        update(
          (c) => c.withParam(
            'limit',
            number?.clamp(1, GoogleDriveSearchFields.limitMax),
          ),
        );
      },
    );
  }
}
