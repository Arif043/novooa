import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/syscat_theme.dart';

/// Zeichen, die ein Lizenz-Token enthalten darf: A–Z ohne I und O, 2–9.
final licenseTokenCharacter = RegExp('[A-HJ-NP-Z2-9]');

/// Eine der 16 Zellen des Lizenz-Tokens. Nimmt beim Tippen ein Zeichen auf;
/// beim Einfügen kommt der ganze Text an, und das Feld verteilt ihn.
class LicenseTokenCell extends StatelessWidget {
  const LicenseTokenCell({
    super.key,
    required this.index,
    required this.length,
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
    required this.onBackspaceOnEmpty,
    this.onSubmitted,
  });

  final int index;
  final int length;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double width;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceOnEmpty;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Quadratisch: Höhe gleich Breite.
      width: width,
      height: width,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _handleBackspace,
        child: Semantics(
          label: 'Lizenz-Token, Zeichen ${index + 1} von $length',
          child: _textField(context),
        ),
      ),
    );
  }

  Widget _textField(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = index == length - 1;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      // Füllt die volle Zellenhöhe, statt nur die Höhe einer Textzeile.
      expands: true,
      maxLines: null,
      keyboardType: TextInputType.visiblePassword,
      textCapitalization: TextCapitalization.characters,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: const [LicenseTokenFormatter()],
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontFamilyFallback: SyscatTheme.codeFontFamilyFallback,
      ),
      decoration: _decoration(theme),
      onChanged: onChanged,
      onTap: _selectCharacter,
      onSubmitted: isLast ? (_) => onSubmitted?.call() : null,
    );
  }

  InputDecoration _decoration(ThemeData theme) {
    final colors = theme.colorScheme;
    // Kantige Ecken.
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      counterText: '',
      isDense: true,
      filled: true,
      fillColor: _fillColor(theme),
      contentPadding: EdgeInsets.zero,
      enabledBorder: border(hasError ? colors.error : colors.outlineVariant, 1),
      focusedBorder: border(hasError ? colors.error : colors.primary, 2),
      disabledBorder: border(colors.outlineVariant, 1),
    );
  }

  /// Weiß; im dunklen Modus die hellste dunkle Fläche, damit es nicht blendet.
  Color _fillColor(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? SyscatTheme.surfaceDarkHigh
        : SyscatTheme.glassSurface;
  }

  /// Ein Tippen ersetzt das vorhandene Zeichen, statt ein zweites anzuhängen.
  void _selectCharacter() {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  KeyEventResult _handleBackspace(FocusNode node, KeyEvent event) {
    final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;
    if (event is! KeyDownEvent || !isBackspace || controller.text.isNotEmpty) {
      return KeyEventResult.ignored;
    }
    onBackspaceOnEmpty();
    return KeyEventResult.handled;
  }
}

/// Großschreibung und nur erlaubte Zeichen — Bindestriche und Leerzeichen
/// aus einem eingefügten Token fallen dabei weg.
class LicenseTokenFormatter extends TextInputFormatter {
  const LicenseTokenFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = licenseTokenCharacter
        .allMatches(newValue.text.toUpperCase())
        .map((match) => match.group(0)!)
        .join();
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
