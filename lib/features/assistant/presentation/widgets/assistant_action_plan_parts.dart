import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class AssistantActionPlanHeader extends StatelessWidget {
  const AssistantActionPlanHeader({
    super.key,
    required this.isRunning,
    required this.isDone,
    required this.onRun,
    required this.onUndo,
  });

  final bool isRunning;
  final bool isDone;
  final VoidCallback? onRun;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _leading(context),
        if (onUndo != null)
          IconButton(
            tooltip: LocaleKeys.ui_rueckgaengig.tr(),
            onPressed: onUndo,
            icon: const Icon(Icons.undo_rounded),
          ),
        _runButton(),
      ],
    );
  }

  Widget _leading(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            Icons.ads_click,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              LocaleKeys.ui_vorschlag_anwenden.tr(),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _runButton() {
    return TextButton.icon(
      onPressed: onRun,
      icon: Icon(isDone ? Icons.check : Icons.play_arrow_rounded),
      label: Text(
        isDone
            ? 'Erledigt'
            : isRunning
            ? LocaleKeys.ui_running.tr()
            : 'Ausführen',
      ),
    );
  }
}

class AssistantActionPlanStep extends StatelessWidget {
  const AssistantActionPlanStep({
    super.key,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.mouse,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
