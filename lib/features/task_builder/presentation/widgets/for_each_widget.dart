import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class ForEachWidget extends StatelessWidget {
  const ForEachWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as ForEachNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.ui_fuer_jedes_element.tr(),
            style: SyscatTheme.taskBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: config.itemsTemplate,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_liste.tr(),
              hintText: '{{erkennung.regions}}',
            ),
            onChanged: (value) => context
                .read<TaskBuilderCubit>()
                .updateForEachItems(node.id, value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: config.itemsPointer,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_elemente_aus.tr(),
              hintText: LocaleKeys.ui_leer_fuer_die_gesamte_liste_z_b_regions
                  .tr(),
            ),
            onChanged: (value) => context
                .read<TaskBuilderCubit>()
                .updateForEachPointer(node.id, value),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            LocaleKeys.ui_der_pfad_waehlt_innerhalb_der_angegebenen_liste.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LocaleKeys.ui_fuer_jedes_gefundene_element.tr(),
            style: SyscatTheme.taskBody,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LocaleKeys.ui_for_each_hint.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
