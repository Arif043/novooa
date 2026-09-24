import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/spreadsheet_document.dart';
import '../../../infrastructure/parsers/xlsx_spreadsheet_parser.dart';
import 'spreadsheet_sheet_table.dart';

/// Renders an XLSX spreadsheet's cells as a scrollable table.
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
    this.parser = const XlsxSpreadsheetParser(),
  });

  final Uint8List bytes;
  final XlsxSpreadsheetParser parser;

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
              : SheetTable(sheet: sheet),
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
