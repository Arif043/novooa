import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/luminous_card.dart';

import '../../domain/entities/employee.dart';
import 'employee_avatar.dart';
import 'employee_delete_dialog.dart';

/// Ein Mitarbeiter als Karte im Stil des Zeitplans: Avatar, Name und Rahmenbedingung oben,
/// Zahl der Fähigkeiten in der Fußzeile. Antippen oder der Stift öffnet den Editor.
class EmployeeCard extends StatelessWidget {
  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Avatar in der Größe der Symbolkacheln anderer Karten.
  static const _avatarSize = AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LuminousCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuminousCardHeading(
            leading: EmployeeAvatar(employeeId: employee.id, size: _avatarSize),
            title: employee.name,
            subtitle: employee.constraint,
            subtitleMaxLines: 3,
          ),
          const SizedBox(height: AppSpacing.gutter),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          _Footer(
            employee: employee,
            onEdit: onEdit,
            onDelete: () => _delete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    if (await confirmEmployeeDeletion(context, employee.name)) onDelete();
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = {'name': employee.name};
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Text(_skillCount, style: theme.textTheme.bodySmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FooterAction(
              icon: CupertinoIcons.pencil,
              tooltip: LocaleKeys.ui_employee_edit_tooltip.tr(namedArgs: name),
              onPressed: onEdit,
            ),
            _FooterAction(
              icon: CupertinoIcons.trash,
              tooltip: LocaleKeys.ui_employee_delete_tooltip.tr(
                namedArgs: name,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }

  String get _skillCount => switch (employee.skillNames.length) {
    0 => LocaleKeys.ui_employee_skills_none.tr(),
    1 => LocaleKeys.ui_skills_count_one.tr(),
    final count => LocaleKeys.ui_skills_count_other.tr(
      namedArgs: {'count': '$count'},
    ),
  };
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.xxl,
        minHeight: AppSpacing.xxl,
      ),
      icon: Icon(
        icon,
        size: AppSpacing.gutter,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
