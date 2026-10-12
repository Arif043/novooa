import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Erster Eindruck des Zeitplans ohne Auslöser: eine zentrierte Einladung mit
/// genau einer Handlung, analog zur Wissensbasis.
class ScheduleEmptyState extends StatelessWidget {
  const ScheduleEmptyState({
    super.key,
    required this.hasTasks,
    required this.onCreateTrigger,
    required this.onCreateTask,
  });

  final bool hasTasks;
  final VoidCallback onCreateTrigger;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.calendar_badge_plus,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: hasTasks ? onCreateTrigger : onCreateTask,
                  icon: const Icon(CupertinoIcons.add),
                  label: Text(_action),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title => hasTasks
      ? LocaleKeys.ui_schedule_empty_title.tr()
      : LocaleKeys.ui_schedule_empty_no_task_title.tr();

  String get _body => hasTasks
      ? LocaleKeys.ui_schedule_empty_body.tr()
      : LocaleKeys.ui_schedule_empty_no_task_body.tr();

  String get _action => hasTasks
      ? LocaleKeys.ui_schedule_empty_create.tr()
      : LocaleKeys.ui_schedule_empty_create_task.tr();
}
