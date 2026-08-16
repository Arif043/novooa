import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_activity.dart';
import 'node_activity_values.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.activity, this.onTap});

  final TaskActivity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusIcon(activity: activity),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _ActivityText(activity: activity)),
              const SizedBox(width: AppSpacing.md),
              Text(_time(activity.occurredAt), style: textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  String _time(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ActivityText extends StatelessWidget {
  const _ActivityText({required this.activity});

  final TaskActivity activity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_title, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(_subtitle, style: textTheme.bodyMedium),
        if (activity.target == TaskActivityTarget.node)
          NodeActivityValues(activity: activity)
        else if (_detail != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_detail!, style: textTheme.bodySmall),
        ],
      ],
    );
  }

  String get _title {
    if (activity.target == TaskActivityTarget.task) return activity.taskTitle;
    return '${_primitiveLabel(activity.primitive)} ausgeführt';
  }

  String get _subtitle {
    final status = _statusLabel(activity.status);
    if (activity.target == TaskActivityTarget.task) return status;
    return '$status · ${activity.nodeId ?? 'Baustein'}';
  }

  String? get _detail {
    final text = activity.message ?? activity.output ?? activity.input;
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }

  String _statusLabel(TaskActivityStatus status) {
    return switch (status) {
      TaskActivityStatus.started => 'Gestartet',
      TaskActivityStatus.succeeded => 'Erfolgreich',
      TaskActivityStatus.failed => 'Fehlgeschlagen',
      TaskActivityStatus.skipped => 'Übersprungen',
      TaskActivityStatus.waiting => 'Wartet',
    };
  }

  String _primitiveLabel(String? primitive) {
    return switch (primitive) {
      'stringInput' => 'Texteingabe',
      'prompt' => 'Prompt',
      'conditionalFlow' => 'Bedingter Ablauf',
      'iterativeRefinement' => 'Iterative Verfeinerung',
      'toolCall' => 'Werkzeug-Aufruf',
      'humanApproval' => 'Freigabe',
      'dialogInput' => 'Formulareingabe',
      'validation' => 'Validierung',
      _ => 'Baustein',
    };
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.activity});

  final TaskActivity activity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _color(colorScheme);
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Icon(_icon),
    );
  }

  IconData get _icon {
    return switch (activity.status) {
      TaskActivityStatus.started => Icons.play_arrow_outlined,
      TaskActivityStatus.succeeded => Icons.check_circle_outline,
      TaskActivityStatus.failed => Icons.error_outline,
      TaskActivityStatus.skipped => Icons.skip_next_outlined,
      TaskActivityStatus.waiting => Icons.pending_actions_outlined,
    };
  }

  Color _color(ColorScheme colorScheme) {
    return switch (activity.status) {
      TaskActivityStatus.started => colorScheme.primary,
      TaskActivityStatus.succeeded => colorScheme.tertiary,
      TaskActivityStatus.failed => colorScheme.error,
      TaskActivityStatus.skipped => colorScheme.outline,
      TaskActivityStatus.waiting => colorScheme.secondary,
    };
  }
}
