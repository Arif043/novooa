import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

import '../../domain/google_drive_node_config.dart';
import 'google_drive_action_widget.dart';

/// Eingaben von „Aus Google Drive lesen“: eine freigegebene Datei oder eine
/// Datei-ID aus einem vorherigen Baustein (etwa `{{driveFileId}}`).
class GoogleDriveReadFields extends StatelessWidget {
  const GoogleDriveReadFields({
    super.key,
    required this.config,
    required this.account,
    required this.update,
  });

  /// Auswahl „Datei-ID aus einem vorherigen Baustein“ im Dropdown.
  static const _byExpression = '\u0000expression';

  final GoogleDriveNodeConfig config;
  final GoogleAccount? account;
  final GoogleDriveNodeUpdate update;

  @override
  Widget build(BuildContext context) {
    final files = account?.sharedFiles ?? const [];
    final fileId = config.textParam('fileId');
    final picked = fileId.isNotEmpty && files.any((f) => f.id == fileId);
    final byExpression =
        config.params['fileSource'] == 'expression' ||
        !picked && fileId.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('drive-file-$fileId-$byExpression-${files.length}'),
          initialValue: byExpression ? _byExpression : (picked ? fileId : null),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: LocaleKeys.google_drive_file.tr(),
          ),
          items: [
            for (final file in files)
              DropdownMenuItem(
                value: file.id,
                child: Text(file.name, overflow: TextOverflow.ellipsis),
              ),
            DropdownMenuItem(
              value: _byExpression,
              child: Text(LocaleKeys.google_drive_file_by_id.tr()),
            ),
          ],
          onChanged: _select,
        ),
        if (byExpression) ...[
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: fileId,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: InputDecoration(
              labelText: LocaleKeys.google_drive_file_id.tr(),
              hintText: LocaleKeys.google_drive_file_id_hint.tr(),
            ),
            onChanged: (value) => update((c) => c.withParam('fileId', value)),
          ),
        ],
      ],
    );
  }

  void _select(String? choice) {
    if (choice == null) return;
    if (choice == _byExpression) {
      update(
        (c) =>
            c.withParam('fileSource', 'expression').withParam('fileId', null),
      );
    } else {
      update(
        (c) => c.withParam('fileSource', null).withParam('fileId', choice),
      );
    }
  }
}
