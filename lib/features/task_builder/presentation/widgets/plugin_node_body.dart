import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';
import 'package:syscat2/features/plugins/presentation/widgets/plugin_disabled_hint.dart';

import '../../domain/entities/plugin_node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../plugin_node_module.dart';

/// Formular eines Plugin-Bausteins. Ist das Plugin deaktiviert, bleibt der
/// Baustein bearbeitbar und trägt einen Hinweis; Läufe scheitern an ihm.
class PluginNodeBody extends StatelessWidget {
  const PluginNodeBody({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config;
    final module = config is PluginNodeConfig
        ? PluginNodeModules.byTypeId(config.typeId)
        : null;
    if (module == null) {
      return Text(LocaleKeys.ui_dieser_baustein_ist_nicht_verfuegbar.tr());
    }
    final isEnabled = context.select<PluginsCubit, bool>(
      (cubit) => cubit.state.isEnabled(PluginId(module.pluginId)),
    );
    if (isEnabled) return module.builder(node);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PluginDisabledHint(),
        const SizedBox(height: AppSpacing.sm),
        module.builder(node),
      ],
    );
  }
}
