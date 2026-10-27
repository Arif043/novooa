import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

/// Fußzeile eines Fenster-Sheets mit den Standard-Schaltflächen nach HIG:
/// Abbrechen schließt ohne Änderung, „Zurück" wechselt nur den Schritt, der
/// Bestätigen-Button schließt nach getaner Arbeit. Alle drei zugleich zeigt
/// man nicht; „Abbrechen" ist immer da, damit „Fertig" nie die einzige Tür ist.
class SheetFooter extends StatelessWidget {
  const SheetFooter({
    super.key,
    required this.onCancel,
    this.onBack,
    this.cancelLabel = 'Abbrechen',
    this.confirmLabel,
    this.onConfirm,
  }) : assert(
         onBack == null || onConfirm == null,
         'Zurück und Bestätigen nicht zugleich zeigen.',
       );

  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final String cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  /// Wie ein iOS-Dialog: Die Aktionen teilen sich die
  /// Breite, getrennt durch dünne Linien; die Bestätigung ist fett. Die
  /// Linie darüber setzt der Aufrufer.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actions = [
      if (onBack != null) _FooterAction(label: 'Zurück', onPressed: onBack),
      _FooterAction(label: cancelLabel, onPressed: onCancel, muted: true),
      if (onConfirm != null)
        _FooterAction(
          label: confirmLabel ?? 'Fertig',
          onPressed: onConfirm,
          emphasized: true,
        ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            if (index > 0)
              VerticalDivider(width: 1, color: colors.outlineVariant),
            Expanded(child: actions[index]),
          ],
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.label,
    required this.onPressed,
    this.emphasized = false,
    this.muted = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;

  /// Zurückgenommen (grau): Abbrechen ist keine Warnung, soll aber hinter der
  /// Bestätigung zurücktreten.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: muted ? _mutedColor(context) : null,
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(),
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

Color _mutedColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SyscatTheme.textMutedDark : SyscatTheme.textMuted;
}
