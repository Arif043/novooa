import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class ReadWebhookWidget extends StatelessWidget {
  const ReadWebhookWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.ui_webhook_ereignis_lesen.tr(),
            style: SyscatTheme.taskBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(LocaleKeys.ui_webhook_hint.tr()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LocaleKeys.ui_ausgaben_inhalt_methode_query_kopfzeilen_zeitpun.tr(),
          ),
        ],
      ),
    );
  }
}
