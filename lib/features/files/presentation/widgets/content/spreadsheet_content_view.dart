import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/spreadsheet_document.dart';
import '../../../infrastructure/parsers/ods_spreadsheet_parser.dart';

/// Renders an ODS spreadsheet's cells as a scrollable table.
///
/// Parses once per [bytes] payload (not on every rebuild) and handles all
/// four states explicitly: loading is implicit (parsing is synchronous, so
/// there is no separate loading frame), a corrupt/unsupported archive shows
/// a friendly error, a document without any filled cell shows an empty
/// state, and the happy path renders the (optionally sheet-switchable)
/// table.
class SpreadsheetContentView extends StatefulWidget {
  const SpreadsheetContentView({
    super.key,
    required this.bytes,
    this.parser = const OdsSpreadsheetParser(),
  });

  final Uint8List bytes;
  final OdsSpreadsheetParser parser;

  @override
  State<SpreadsheetContentView> createState() =>
      _SpreadsheetContentViewState();
}

class _SpreadsheetContentViewState extends State<SpreadsheetContentView> {
  SpreadsheetDocument? _document;
  Object? _error;
  int _selectedSheetIndex = 0;

  @override
  void initState() {
    super.initState();
    _parse(widget.bytes);
  }

  @override
  void didUpdateWidget(covariant SpreadsheetContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.bytes, widget.bytes)) return;
    _selectedSheetIndex = 0;
    _parse(widget.bytes);
  }

  void _parse(Uint8List bytes) {
    try {
      _document = widget.parser.parse(bytes);
      _error = null;
    } on Object catch (error) {
      _document = null;
      _error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) return _SpreadsheetLoadError(error: error);
    final document = _document!;
    if (document.isEmpty) return const _EmptySpreadsheet();
    return _Table(
      document: document,
      selectedSheetIndex: _selectedSheetIndex,
      onSheetSelected: (index) => setState(() => _selectedSheetIndex = index),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.document,
    required this.selectedSheetIndex,
    required this.onSheetSelected,
  });

  final SpreadsheetDocument document;
  final int selectedSheetIndex;
  final ValueChanged<int> onSheetSelected;

  @override
  Widget build(BuildContext context) {
    final sheet = document.sheets[selectedSheetIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (document.sheets.length > 1) ...[
          _SheetSelector(
            sheets: document.sheets,
            selectedIndex: selectedSheetIndex,
            onSelected: onSheetSelected,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // Der Dokument-weite Leer-Zustand fängt nur ab, wenn ALLE Blätter
        // leer sind — ein einzelnes leeres Blatt (z.B. nach Umschalten über
        // den Sheet-Selector) braucht denselben Leer-Zustand hier erneut,
        // sonst würde DataTable mit null Spalten gebaut werden.
        Expanded(
          child: sheet.isEmpty
              ? const _EmptySpreadsheet()
              : _SheetTable(sheet: sheet),
        ),
      ],
    );
  }
}

class _SheetSelector extends StatelessWidget {
  const _SheetSelector({
    required this.sheets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SpreadsheetSheet> sheets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DropdownButton<int>(
        value: selectedIndex,
        onChanged: (index) {
          if (index != null) onSelected(index);
        },
        items: [
          for (var index = 0; index < sheets.length; index++)
            DropdownMenuItem(value: index, child: Text(sheets[index].name)),
        ],
      ),
    );
  }
}

/// Renders [sheet] as an Excel/Sheets-style grid: lettered column headers
/// (A, B, C, …), numbered row headers (1, 2, 3, …) and full gridlines —
/// familiar spreadsheet chrome around the actual cell data.
class _SheetTable extends StatelessWidget {
  const _SheetTable({required this.sheet});

  final SpreadsheetSheet sheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Tabellenblatt ${sheet.name}',
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: theme.colorScheme.outlineVariant),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              _headerRow(theme),
              for (var index = 0; index < sheet.rows.length; index++)
                _dataRow(theme, index),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _headerRow(ThemeData theme) {
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return TableRow(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      children: [
        const _GridCell(text: ''),
        for (var index = 0; index < sheet.columnCount; index++)
          _GridCell(
            text: spreadsheetColumnLabel(index),
            textStyle: headerStyle,
            alignment: Alignment.center,
          ),
      ],
    );
  }

  TableRow _dataRow(ThemeData theme, int rowIndex) {
    return TableRow(
      children: [
        _GridCell(
          text: '${rowIndex + 1}',
          textStyle: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          alignment: Alignment.center,
          background: theme.colorScheme.surfaceContainerHighest,
        ),
        for (final value in sheet.rows[rowIndex])
          _GridCell(text: _cellText(value)),
      ],
    );
  }

  String _cellText(Object? value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Ja' : 'Nein';
    if (value is num) {
      final rounded = value.roundToDouble();
      return value == rounded ? rounded.toInt().toString() : value.toString();
    }
    return value.toString();
  }
}

/// A single spreadsheet grid cell — a padded, optionally shaded and aligned
/// text container. Shared by header cells (column letters, row numbers) and
/// plain data cells so the grid's visual rhythm stays consistent.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.text,
    this.textStyle,
    this.alignment = Alignment.centerLeft,
    this.background,
  });

  final String text;
  final TextStyle? textStyle;
  final Alignment alignment;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(text, style: textStyle),
    );
  }
}

class _SpreadsheetLoadError extends StatelessWidget {
  const _SpreadsheetLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        label: 'Tabelle konnte nicht gelesen werden',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Tabelle konnte nicht gelesen werden.'),
          ],
        ),
      ),
    );
  }
}

class _EmptySpreadsheet extends StatelessWidget {
  const _EmptySpreadsheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        label: 'Diese Tabelle enthält keine Daten',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Diese Tabelle enthält keine Daten.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
