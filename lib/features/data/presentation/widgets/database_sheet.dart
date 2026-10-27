import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'database_sheet_options.dart';
import 'database_sheet_rows.dart';

/// A bounded, horizontally scrollable sheet with a fixed header and lazy rows. Optional: a
/// selection column, sortable headers and a trailing action per row.
class DatabaseSheet extends StatefulWidget {
  const DatabaseSheet({
    super.key,
    required this.columns,
    required this.rows,
    required this.onOpen,
    this.trailingBuilder,
    this.selection,
    this.sort,
    this.enabled = true,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final ValueChanged<int> onOpen;
  final Widget Function(BuildContext context, int row)? trailingBuilder;
  final DatabaseSheetSelection? selection;
  final DatabaseSheetSort? sort;
  final bool enabled;

  @override
  State<DatabaseSheet> createState() => _DatabaseSheetState();
}

class _DatabaseSheetState extends State<DatabaseSheet> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  double get _fixedWidth =>
      DatabaseSheetWidths.index +
      (widget.selection == null ? 0 : DatabaseSheetWidths.selection) +
      (widget.trailingBuilder == null ? 0 : DatabaseSheetWidths.trailing);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => _scrollable(context, constraints),
      ),
    );
  }

  Widget _scrollable(BuildContext context, BoxConstraints constraints) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cellWidth = math.max(
      200.0 * math.min(scale, 1.5),
      (constraints.maxWidth - _fixedWidth) / math.max(1, widget.columns.length),
    );
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _fixedWidth + cellWidth * widget.columns.length,
          height: constraints.maxHeight,
          child: _table(context, cellWidth, scale),
        ),
      ),
    );
  }

  Widget _table(BuildContext context, double cellWidth, double scale) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: math.max(72.0, 44 * scale + 20),
          child: ColoredBox(
            color: colors.surfaceContainerLow,
            child: DatabaseSheetHeader(
              columns: widget.columns,
              cellWidth: cellWidth,
              selection: widget.selection,
              sort: widget.sort,
              hasTrailing: widget.trailingBuilder != null,
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _vertical,
            child: ListView.builder(
              controller: _vertical,
              itemExtent: math.max(52.0, 32 * scale + 20),
              itemCount: widget.rows.length,
              itemBuilder: (context, index) => DatabaseSheetRow(
                index: index,
                values: widget.rows[index],
                cellWidth: cellWidth,
                onOpen: widget.enabled ? () => widget.onOpen(index) : null,
                selection: widget.selection,
                trailing: widget.trailingBuilder?.call(context, index),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
      ],
    );
  }
}
