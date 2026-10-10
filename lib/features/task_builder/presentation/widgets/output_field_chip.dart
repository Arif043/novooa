import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_execution_result.dart';
import 'node_output_type_style.dart';

/// Ein Ausgabewert im Panel. Mit [onRename] öffnet Antippen das Umbenennen
/// und das Kopier-Symbol kopiert `{{name}}`; ohne kopiert Antippen direkt
/// (Felder, die in ihrem eigenen Editor benannt werden).
class OutputFieldChip extends StatelessWidget {
  const OutputFieldChip({
    super.key,
    required this.name,
    required this.type,
    this.onRename,
  });

  final String name;
  final NodeOutputType type;
  final VoidCallback? onRename;

  String get _expression => '{{$name}}';

  @override
  Widget build(BuildContext context) {
    final style = NodeOutputTypeStyle.of(type);
    final rename = onRename;
    return Tooltip(
      message: rename == null
          ? LocaleKeys.ui_tap_to_copy.tr(
              namedArgs: {'type': style.label, 'expression': _expression},
            )
          : LocaleKeys.ui_edit_output_name_typed.tr(
              namedArgs: {'type': style.label},
            ),
      child: InputChip(
        avatar: Icon(style.icon, size: AppSpacing.md, color: style.color),
        label: Text(name),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: style.color.withValues(alpha: 0.12),
        side: BorderSide(color: style.color.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
        onPressed: rename ?? () => _copyExpression(context),
        onDeleted: rename == null ? null : () => _copyExpression(context),
        deleteIcon: const Icon(Icons.copy, size: AppSpacing.md),
        deleteButtonTooltipMessage: LocaleKeys.ui_copy_expression.tr(
          namedArgs: {'expression': _expression},
        ),
      ),
    );
  }

  Future<void> _copyExpression(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _expression));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocaleKeys.ui_expression_copied.tr(
            namedArgs: {'expression': _expression},
          ),
        ),
      ),
    );
  }
}
