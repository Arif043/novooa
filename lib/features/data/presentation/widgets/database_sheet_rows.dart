import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import 'database_sheet_cell.dart';
import 'database_sheet_options.dart';

/// Feste Breiten der Randspalten; Datenspalten teilen sich den Rest.
abstract final class DatabaseSheetWidths {
  static const index = 56.0;
  static const selection = AppSpacing.xxl;
  static const trailing = 56.0;
}

class DatabaseSheetHeader extends StatelessWidget {
  const DatabaseSheetHeader({
    super.key,
    required this.columns,
    required this.cellWidth,
    this.selection,
    this.sort,
    this.hasTrailing = false,
  });

  final List<String> columns;
  final double cellWidth;
  final DatabaseSheetSelection? selection;
  final DatabaseSheetSort? sort;
  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DatabaseSheetCell(
          text: '#',
          width: DatabaseSheetWidths.index,
          header: true,
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
            width: cellWidth,
            sort: sort,
          ),
        if (hasTrailing)
          const DatabaseSheetCell(
            text: '',
            width: DatabaseSheetWidths.trailing,
            header: true,
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.name,
    required this.width,
    required this.sort,
  });

  final int column;
  final String name;
  final double width;
  final DatabaseSheetSort? sort;

  @override
  Widget build(BuildContext context) {
    final sort = this.sort;
    final cell = DatabaseSheetCell(
      text: name,
      width: width,
      header: true,
      letter: databaseColumnLetter(column),
      trailing: sort?.column == column
          ? Icon(
              sort!.ascending
                  ? CupertinoIcons.arrow_up
                  : CupertinoIcons.arrow_down,
              size: AppSpacing.md,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
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
  final List<String> values;
  final double cellWidth;
  final VoidCallback? onOpen;
  final DatabaseSheetSelection? selection;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = selection?.isSelected(index) ?? false;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: .08)
          : index.isEven
          ? colors.surface
          : colors.surfaceContainerLow.withValues(alpha: .45),
      child: InkWell(
        onTap: onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DatabaseSheetCell(
              text: '${index + 1}',
              width: DatabaseSheetWidths.index,
              header: true,
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
              DatabaseSheetCell(text: value, width: cellWidth),
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
    return Container(
      width: DatabaseSheetWidths.selection,
      decoration: databaseCellBorder(Theme.of(context).colorScheme),
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
