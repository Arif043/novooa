import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// Wie ein Sheet dargestellt wird.
enum AdaptiveSheetStyle {
  /// Bottom Sheet mit Greifer — iOS- und Android-Muster.
  bottom,

  /// Karte oben mittig über dem abgedunkelten Fenster — macOS-Muster.
  window;

  bool get isWindow => this == AdaptiveSheetStyle.window;
}

/// Ab dieser Fensterbreite gilt das Layout als Desktop (Material „compact"
/// endet bei 600 dp). Darunter bleibt es beim Bottom Sheet — auch auf dem
/// Desktop, etwa in einem schmalen Browserfenster oder in der Geräteemulation,
/// die weiterhin „macOS" meldet.
const desktopSheetMinWidth = 600.0;

/// Fenster-Sheet nur auf einem Desktop-Betriebssystem *und* in einem
/// ausreichend breiten Fenster; sonst Bottom Sheet. Die Breite entscheidet,
/// weil das Muster zur Layoutgröße passen muss, nicht zum Betriebssystem.
AdaptiveSheetStyle adaptiveSheetStyle(BuildContext context) {
  final isDesktopPlatform = switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    TargetPlatform.iOS ||
    TargetPlatform.android ||
    TargetPlatform.fuchsia => false,
  };
  final isWide = MediaQuery.sizeOf(context).width >= desktopSheetMinWidth;
  return isDesktopPlatform && isWide
      ? AdaptiveSheetStyle.window
      : AdaptiveSheetStyle.bottom;
}

/// Zeigt [builder] als Sheet in der Form der Plattform. Der Inhalt bekommt den
/// [AdaptiveSheetStyle], damit er seine Schaltflächen passend anordnen kann
/// (siehe [SheetFooter]).
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, AdaptiveSheetStyle style)
  builder,
}) {
  final style = adaptiveSheetStyle(context);
  if (style.isWindow) return _showWindowSheet<T>(context, builder);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => builder(sheetContext, style),
  );
}

/// macOS-Sheet nach den Apple-HIG: modal, kartenartig mit runden Ecken, über
/// dem abgedunkelten Elternfenster, in angemessener Standardgröße. Es lässt
/// sich nicht durch Tippen daneben schließen; Escape bricht ab.
Future<T?> _showWindowSheet<T>(
  BuildContext context,
  Widget Function(BuildContext, AdaptiveSheetStyle) builder,
) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (sheetContext, _, _) =>
        _WindowSheet(child: builder(sheetContext, AdaptiveSheetStyle.window)),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _WindowSheet extends StatelessWidget {
  const _WindowSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: height * 0.8,
                ),
                child: Material(
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fußzeile eines Fenster-Sheets mit den Standard-Schaltflächen nach HIG:
/// Abbrechen schließt ohne Änderung, „Zurück" wechselt nur den Schritt, der
/// Bestätigen-Button schließt nach getaner Arbeit. Alle drei zugleich zeigt
/// man nicht; „Abbrechen" ist immer da, damit „Fertig" nie die einzige Tür ist.
class SheetFooter extends StatelessWidget {
  const SheetFooter({
    super.key,
    required this.onCancel,
    this.onBack,
    this.confirmLabel,
    this.onConfirm,
  }) : assert(
         onBack == null || onConfirm == null,
         'Zurück und Bestätigen nicht zugleich zeigen.',
       );

  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (onBack != null)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Zurück'),
            ),
          const Spacer(),
          TextButton(onPressed: onCancel, child: const Text('Abbrechen')),
          if (onConfirm != null) ...[
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: onConfirm,
              child: Text(confirmLabel ?? 'Fertig'),
            ),
          ],
        ],
      ),
    );
  }
}
