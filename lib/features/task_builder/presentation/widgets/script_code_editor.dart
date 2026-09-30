import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';

/// Rendert einen `CodeField` für Python-Skripte — geteilt zwischen der
/// kompakten Vorschau im Konfigurations-Panel ([ScriptWidget]) und dem
/// Vollbild-Editor ([showScriptFullscreenEditor]). Beide binden dieselbe
/// [CodeController]-Instanz, Änderungen bleiben also ohne zusätzlichen
/// Synchronisierungscode identisch.
class ScriptCodeEditor extends StatelessWidget {
  const ScriptCodeEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    this.expands = false,
    this.minLines,
    this.maxLines,
  });

  final CodeController controller;
  final ValueChanged<String> onChanged;
  final bool expands;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: _themeData(context),
      child: CodeField(
        controller: controller,
        decoration: _decoration(context),
        minLines: minLines,
        maxLines: maxLines,
        expands: expands,
        // Lange Zeilen umbrechen statt sie in der schmalen Panel-Breite
        // abzuschneiden — Skripte sind zum Schreiben da, nicht nur zur
        // Anzeige.
        wrap: true,
        textStyle: GoogleFonts.jetBrainsMono(),
        gutterStyle: _gutterStyle(context),
        onChanged: onChanged,
      ),
    );
  }

  CodeThemeData _themeData(BuildContext context) {
    return CodeThemeData(
      styles: Theme.of(context).brightness == Brightness.dark
          ? atomOneDarkTheme
          : atomOneLightTheme,
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.secondary,
    );
  }

  GutterStyle _gutterStyle(BuildContext context) {
    return GutterStyle(
      width: AppSpacing.xl,
      margin: 0,
      textStyle: GoogleFonts.jetBrainsMono(
        color: ColorScheme.of(context).onSecondary,
      ),
      showErrors: true,
      showLineNumbers: true,
      showFoldingHandles: true,
      background: Theme.of(context).colorScheme.surfaceContainerLow,
    );
  }
}
