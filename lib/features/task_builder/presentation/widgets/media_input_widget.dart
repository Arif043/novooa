import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/platform/document_scan_support.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class MediaInputWidget extends StatelessWidget {
  const MediaInputWidget({super.key, required this.node});

  final WorkflowNode node;

  MediaInputNodeConfig get _config => node.config as MediaInputNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.ui_bild_anfordern.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.instruction,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: LocaleKeys.ui_hinweis_fuer_die_bildeingabe.tr(),
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(instruction: value),
            ),
          ),
          if (documentScanSupportedOnThisPlatform()) ...[
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(LocaleKeys.ui_als_dokument_scannen.tr()),
              subtitle: Text(LocaleKeys.ui_scan_hint.tr()),
              value: _config.documentScanEnabled,
              onChanged: (value) => _update(
                context,
                (config) => config.copyWith(documentScanEnabled: value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    MediaInputNodeConfig Function(MediaInputNodeConfig config) update,
  ) {
    context.read<TaskBuilderCubit>().updateMediaInput(node.id, update);
  }
}
