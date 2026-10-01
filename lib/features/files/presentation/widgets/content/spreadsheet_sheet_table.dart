import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/spreadsheet_document.dart';

/// Renders [sheet] as an Excel/Sheets-style grid: lettered column headers
/// (A, B, C, …), numbered row headers (1, 2, 3, …) and full gridlines.
///
/// Cells the source file itself marks bold, or gives a font/fill color
/// (`CellStyle`, via `package:excel`), render that way here too. `excel`
/// doesn't expose hyperlink relationships though, so cell values that
/// merely look like an email address or web URL are additionally offered
/// as tappable links.
class SheetTable extends StatelessWidget {
  const SheetTable({super.key, required this.sheet});

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
        for (final cell in sheet.rows[rowIndex]) _dataCell(theme, cell),
      ],
    );
  }

  _GridCell _dataCell(ThemeData theme, SpreadsheetCell cell) {
    final fontColor = cell.fontColor;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: cell.isBold ? FontWeight.bold : null,
      color: fontColor == null ? null : Color(fontColor.argb),
    );
    final background = cell.backgroundColor;
    return _GridCell(
      text: _cellText(cell.value),
      textStyle: textStyle,
      background: background == null ? null : Color(background.argb),
      link: spreadsheetCellLink(cell.value),
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
/// plain data cells so the grid's visual rhythm stays consistent. Renders as
/// a tappable [_CellLink] instead of plain text when [link] is set.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.text,
    this.textStyle,
    this.alignment = Alignment.centerLeft,
    this.background,
    this.link,
  });

  final String text;
  final TextStyle? textStyle;
  final Alignment alignment;
  final Color? background;
  final Uri? link;

  @override
  Widget build(BuildContext context) {
    final cellLink = link;
    return Container(
      color: background,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: cellLink == null
          ? Text(text, style: textStyle)
          : _CellLink(text: text, link: cellLink, baseStyle: textStyle),
    );
  }
}

/// An underlined, tappable cell value that opens [link] in the system
/// browser/mail client — the same launch-and-report-failure pattern as
/// `AssistantMessageSources`' source tiles.
class _CellLink extends StatelessWidget {
  const _CellLink({required this.text, required this.link, this.baseStyle});

  final String text;
  final Uri link;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      link: true,
      label: 'Link zu $text',
      child: InkWell(
        onTap: () => _open(context),
        child: Text(
          text,
          style: (baseStyle ?? theme.textTheme.bodyMedium)?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link konnte nicht geöffnet werden.')),
      );
    }
  }
}
