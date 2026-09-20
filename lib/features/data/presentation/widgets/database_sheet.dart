import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A bounded, horizontally scrollable sheet with a fixed header and lazy rows.
class DatabaseSheet extends StatefulWidget {
  const DatabaseSheet({
    super.key,
    required this.columns,
    required this.rows,
    required this.onOpen,
    this.onDelete,
    this.enabled = true,
  });
  final List<String> columns;
  final List<List<String>> rows;
  final ValueChanged<int> onOpen;
  final ValueChanged<int>? onDelete;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final rowHeight = math.max(52.0, 32 * scale + 20);
    final headerHeight = math.max(72.0, 44 * scale + 20);
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionsWidth = widget.onDelete == null ? 0.0 : 56.0;
          final cellWidth = math.max(
            200.0 * math.min(scale, 1.5),
            (constraints.maxWidth - 56 - actionsWidth) /
                math.max(1, widget.columns.length),
          );
          final width = 56 + cellWidth * widget.columns.length + actionsWidth;
          return Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: ColoredBox(
                        color: colors.surfaceContainerLow,
                        child: Row(
                          children: [
                            _cell(context, '#', 56, header: true),
                            for (var i = 0; i < widget.columns.length; i++)
                              _cell(
                                context,
                                widget.columns[i],
                                cellWidth,
                                header: true,
                                letter: _letter(i),
                              ),
                            if (widget.onDelete != null)
                              _cell(context, '', actionsWidth, header: true),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _vertical,
                        child: ListView.builder(
                          controller: _vertical,
                          itemExtent: rowHeight,
                          itemCount: widget.rows.length,
                          itemBuilder: (context, index) => Material(
                            color: index.isEven
                                ? colors.surface
                                : colors.surfaceContainerLow.withValues(
                                    alpha: .45,
                                  ),
                            child: InkWell(
                              onTap: widget.enabled
                                  ? () => widget.onOpen(index)
                                  : null,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _cell(
                                    context,
                                    '${index + 1}',
                                    56,
                                    header: true,
                                  ),
                                  for (final value in widget.rows[index])
                                    _cell(context, value, cellWidth),
                                  if (widget.onDelete != null)
                                    SizedBox(
                                      width: actionsWidth,
                                      child: IconButton(
                                        tooltip: 'Datensatz löschen',
                                        onPressed: widget.enabled
                                            ? () => widget.onDelete!(index)
                                            : null,
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    String text,
    double width, {
    bool header = false,
    String? letter,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Tooltip(
        message: text,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (letter != null) Text(letter, style: theme.textTheme.bodySmall),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: header
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _letter(int index) {
    var result = '';
    for (var value = index + 1; value > 0; value = (value - 1) ~/ 26) {
      result = String.fromCharCode(65 + (value - 1) % 26) + result;
    }
    return result;
  }
}
