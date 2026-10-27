import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import 'database_cell_value.dart';
import 'database_sheet_cell.dart';
import 'database_sheet_options.dart';

/// Feste Breiten der Randspalten; Datenspalten teilen sich den Rest.
abstract final class DatabaseSheetWidths {
  static const index = AppSpacing.xxl;
  static const selection = AppSpacing.xxl;
  static const trailing = 56.0;
}

class DatabaseSheetHeader extends StatelessWidget {
  const DatabaseSheetHeader({
    super.key,
    required this.columns,
    required this.kinds,
    required this.cellWidth,
    this.selection,
    this.sort,
    this.hasTrailing = false,
  });

  final List<String> columns;
  final List<DatabaseValueKind> kinds;
  final double cellWidth;
  final DatabaseSheetSelection? selection;
  final DatabaseSheetSort? sort;
  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DatabaseSheetCell(
          value: DatabaseCellValue('#'),
          width: DatabaseSheetWidths.index,
          muted: true,
        ),
        if (selection case final selection?)
          _SelectionCell(
            label: LocaleKeys.ui_db_select_all.tr(),
            value: selection.allSelected
                ? true
                : (selection.anySelected ? null : false),
            onChanged: selection.onToggleAll,
          ),
        for (var index = 0; index < columns.length; index++)
          _HeaderCell(
            column: index,
            name: columns[index],
            kind: index < kinds.length ? kinds[index] : DatabaseValueKind.text,
            width: cellWidth,
            sort: sort,
          ),
        if (hasTrailing)
          const DatabaseCellFrame(
            width: DatabaseSheetWidths.trailing,
            child: SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.name,
    required this.kind,
    required this.width,
    required this.sort,
  });

  final int column;
  final String name;
  final DatabaseValueKind kind;
  final double width;
  final DatabaseSheetSort? sort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sort = this.sort;
    final sorted = sort?.column == column;
    final cell = DatabaseCellFrame(
      width: width,
      child: Row(
        children: [
          Icon(kind.icon, size: AppSpacing.md, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Tooltip(
              message: name,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          if (sorted)
            Icon(
              sort!.ascending
                  ? CupertinoIcons.arrow_up
                  : CupertinoIcons.arrow_down,
              size: AppSpacing.md,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
    if (sort == null || !sort.isSortable(column)) return cell;
    return Semantics(
      button: true,
      label: LocaleKeys.ui_db_sort_by.tr(namedArgs: {'field': name}),
      child: InkWell(onTap: () => sort.onSort(column), child: cell),
    );
  }
}

class DatabaseSheetRow extends StatelessWidget {
  const DatabaseSheetRow({
    super.key,
    required this.index,
    required this.values,
    required this.cellWidth,
    required this.onOpen,
    this.selection,
    this.trailing,
  });

  final int index;
  final List<DatabaseCellValue> values;
  final double cellWidth;
  final VoidCallback? onOpen;
  final DatabaseSheetSelection? selection;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = selection?.isSelected(index) ?? false;
    return Material(
      color: selected ? colors.primary.withValues(alpha: .08) : colors.surface,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DatabaseSheetCell(
              value: DatabaseCellValue('${index + 1}'),
              width: DatabaseSheetWidths.index,
              muted: true,
            ),
            if (selection case final selection?)
              _SelectionCell(
                label: LocaleKeys.ui_db_select_record.tr(
                  namedArgs: {'index': '${index + 1}'},
                ),
                value: selected,
                onChanged: () => selection.onToggleRow(index),
              ),
            for (final value in values)
              DatabaseSheetCell(value: value, width: cellWidth),
            if (trailing != null)
              SizedBox(width: DatabaseSheetWidths.trailing, child: trailing),
          ],
        ),
      ),
    );
  }
}

class _SelectionCell extends StatelessWidget {
  const _SelectionCell({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;

  /// `null` zeigt den Zwischenzustand der Kopf-Checkbox (einige ausgewählt).
  final bool? value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return DatabaseCellFrame(
      width: DatabaseSheetWidths.selection,
      alignment: Alignment.center,
      child: Semantics(
        label: label,
        child: Checkbox(
          value: value,
          tristate: value == null,
          onChanged: (_) => onChanged(),
        ),
      ),
    );
  }
}
