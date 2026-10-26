import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_activation.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';

import '../../domain/entities/plugin_node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../plugin_node_module.dart';

/// Ausrufezeichen an einem Baustein der Leinwand, dessen Plugin deaktiviert
/// ist. Andere Bausteine fragen den [PluginsCubit] gar nicht erst.
class PluginDisabledBadge extends StatelessWidget {
  const PluginDisabledBadge({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config;
    final module = config is PluginNodeConfig
        ? PluginNodeModules.byTypeId(config.typeId)
        : null;
    if (module == null) return const SizedBox.shrink();
    final isEnabled = context.select<PluginsCubit, bool>(
      (cubit) => cubit.state.isEnabled(PluginId(module.pluginId)),
    );
    if (isEnabled) return const SizedBox.shrink();
    return const _Badge();
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hint = LocaleKeys.plugins_disabled_hint.tr();
    return Tooltip(
      message: hint,
      child: Semantics(
        label: hint,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs / 2),
          decoration: BoxDecoration(
            color: colors.error,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.priority_high,
            size: AppSpacing.md,
            color: colors.onError,
          ),
        ),
      ),
    );
  }
}
