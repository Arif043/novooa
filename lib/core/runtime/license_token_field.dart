import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'license_token_cell.dart';

/// Eingabe des 16-stelligen Lizenz-Tokens: je Zeichen eine Zelle, in vier
/// Vierergruppen. Tippen springt zur nächsten Zelle, die Rücktaste in einer
/// leeren Zelle zur vorherigen. Ein eingefügter Token — auch mit Bindestrichen
/// — verteilt sich ab der aktuellen Zelle (Einfügen bleibt bewusst erlaubt).
class LicenseTokenField extends StatefulWidget {
  const LicenseTokenField({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
  });

  /// Der bisher eingegebene Token, 0 bis [length] Zeichen ohne Trenner.
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  static const int length = 16;
  static const int groupSize = 4;

  @override
  State<LicenseTokenField> createState() => _LicenseTokenFieldState();
}

class _LicenseTokenFieldState extends State<LicenseTokenField> {
  final _controllers = List.generate(
    LicenseTokenField.length,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _focusNodes = List.generate(
    LicenseTokenField.length,
    _focusNodeFor,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.autofocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Fokus markiert das Zeichen, damit Tippen es ersetzt statt anzuhängen.
  FocusNode _focusNodeFor(int index) {
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus) return;
      final controller = _controllers[index];
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
    return node;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (_, constraints) => _cells(constraints)),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _cells(BoxConstraints constraints) {
    final layout = _TokenLayout.forWidth(constraints.maxWidth);
    return Wrap(
      spacing: _TokenLayout.groupGap,
      runSpacing: AppSpacing.sm,
      children: [
        for (
          var group = 0;
          group < LicenseTokenField.length ~/ LicenseTokenField.groupSize;
          group++
        )
          _group(group, layout.cellWidth),
      ],
    );
  }

  Widget _group(int group, double cellWidth) {
    final start = group * LicenseTokenField.groupSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _TokenLayout.cellGap,
      children: [
        for (
          var index = start;
          index < start + LicenseTokenField.groupSize;
          index++
        )
          LicenseTokenCell(
            index: index,
            length: LicenseTokenField.length,
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            width: cellWidth,
            enabled: widget.enabled,
            hasError: widget.errorText != null,
            onChanged: (value) => _onCellChanged(index, value),
            onBackspaceOnEmpty: () => _moveBackFrom(index),
            onSubmitted: widget.onSubmitted,
          ),
      ],
    );
  }

  void _onCellChanged(int index, String value) {
    if (value.length > 1) {
      _distribute(index, value);
    } else if (value.length == 1) {
      _focusCell(index + 1);
    }
    widget.onChanged(_controllers.map((controller) => controller.text).join());
  }

  /// Verteilt einen eingefügten Text ab [index]; was nicht mehr passt, entfällt.
  void _distribute(int index, String value) {
    var target = index;
    for (final character in value.split('')) {
      if (target >= LicenseTokenField.length) break;
      _controllers[target].text = character;
      target++;
    }
    _focusCell(target);
  }

  void _moveBackFrom(int index) {
    if (index == 0) return;
    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
    widget.onChanged(_controllers.map((controller) => controller.text).join());
  }

  void _focusCell(int index) {
    if (index < LicenseTokenField.length) {
      _focusNodes[index].requestFocus();
    } else {
      _focusNodes.last.unfocus();
    }
  }
}

/// Wie viele Vierergruppen in eine Zeile passen, ohne dass eine Zelle
/// schmaler als [minCellWidth] wird: 4, 2 oder 1 Gruppe je Zeile.
class _TokenLayout {
  const _TokenLayout(this.cellWidth);

  final double cellWidth;

  static const double cellGap = AppSpacing.xs;
  static const double groupGap = AppSpacing.sm + AppSpacing.xs;

  /// Darunter bricht die Reihe in Gruppen um (schmale Bildschirme) — die
  /// Zellen sind quadratisch und sollen bedienbar bleiben.
  static const double minCellWidth = 32;
  static const double maxCellWidth = 52;

  factory _TokenLayout.forWidth(double width) {
    for (final groupsPerRow in const [4, 2, 1]) {
      final gaps = groupsPerRow * 3 * cellGap + (groupsPerRow - 1) * groupGap;
      // Abrunden, damit Rundungsfehler keine Gruppe in die nächste Zeile schieben.
      final cellWidth = ((width - gaps) / (groupsPerRow * 4)).floorToDouble();
      if (cellWidth >= minCellWidth || groupsPerRow == 1) {
        return _TokenLayout(cellWidth.clamp(0, maxCellWidth).toDouble());
      }
    }
    return const _TokenLayout(minCellWidth);
  }
}
