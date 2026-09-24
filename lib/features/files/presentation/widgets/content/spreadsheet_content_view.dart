import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/spreadsheet_document.dart';
import '../../../infrastructure/parsers/xlsx_spreadsheet_parser.dart';
import 'spreadsheet_sheet_table.dart';

/// Renders an XLSX spreadsheet's cells as a scrollable table.
///
/// Parses once per [bytes] payload (not on every rebuild) and handles all
/// four states explicitly: a genuine loading spinner while the parse runs,
/// a corrupt/unsupported archive shows a friendly error, a document without
/// any filled cell shows an empty state, and the happy path renders the
/// (optionally sheet-switchable) table.
///
/// Parsing runs on a background isolate via [compute] — a large spreadsheet
/// is real, synchronous CPU work (`package:excel` decoding an entire
/// workbook) that would otherwise jank the UI thread while it runs.
class SpreadsheetContentView extends StatefulWidget {
  const SpreadsheetContentView({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<SpreadsheetContentView> createState() =>
      _SpreadsheetContentViewState();
}

class _SpreadsheetContentViewState extends State<SpreadsheetContentView> {
  SpreadsheetDocument? _document;
  Object? _error;
  bool _isLoading = true;
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
    _isLoading = true;
    _parse(widget.bytes);
  }

  Future<void> _parse(Uint8List bytes) async {
    try {
      final document = await compute(_parseXlsxDocument, bytes);
      if (!mounted) return;
      setState(() {
        _document = document;
        _error = null;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _document = null;
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const _SpreadsheetLoading();
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

/// Top-level so [compute] can send it to a background isolate — instance
/// methods (even on a stateless, `const`-constructible class like
/// [XlsxSpreadsheetParser]) implicitly capture `this` and can't cross an
/// isolate boundary.
SpreadsheetDocument _parseXlsxDocument(Uint8List bytes) {
  return const XlsxSpreadsheetParser().parse(bytes);
}

class _SpreadsheetLoading extends StatelessWidget {
  const _SpreadsheetLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Tabelle wird geladen',
        child: const CircularProgressIndicator(),
      ),
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
