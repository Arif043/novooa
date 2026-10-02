import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show VerticalDivider;

import '../../../../core/theme/app_spacing.dart';

/// Fußzeile im Stil eines iOS-Dialogs: Haarlinie darüber, zwei gleich breite
/// Aktionen nebeneinander, getrennt durch eine senkrechte Haarlinie. Die
/// Standardaktion ist fett, „Abbrechen" normal.
class TriggerDialogActions extends StatelessWidget {
  const TriggerDialogActions({
    super.key,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isBusy = false,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;

  /// `null` deaktiviert die Standardaktion.
  final VoidCallback? onConfirm;

  /// Zeigt statt des Beschriftungstextes einen Ladeindikator.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: separator, width: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TriggerDialogAction(
                onPressed: onCancel,
                child: Text(cancelLabel),
              ),
            ),
            VerticalDivider(width: 0.5, thickness: 0.5, color: separator),
            Expanded(
              child: TriggerDialogAction(
                isDefaultAction: true,
                onPressed: onConfirm,
                child: isBusy
                    ? const CupertinoActivityIndicator()
                    : Text(confirmLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Aktion eines iOS-Dialogs. Anders als `CupertinoDialogAction` reagiert
/// sie auch außerhalb eines `CupertinoAlertDialog` auf Taps.
class TriggerDialogAction extends StatefulWidget {
  const TriggerDialogAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDefaultAction = false,
  });

  final VoidCallback? onPressed;
  final Widget child;

  /// Die vorgeschlagene Aktion wird fett gesetzt.
  final bool isDefaultAction;

  @override
  State<TriggerDialogAction> createState() => _TriggerDialogActionState();
}

class _TriggerDialogActionState extends State<TriggerDialogAction> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final color = _enabled
        ? CupertinoTheme.of(context).primaryColor
        : CupertinoColors.tertiaryLabel.resolveFrom(context);
    return Semantics(
      button: true,
      enabled: _enabled,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: ColoredBox(
          color: _pressed
              ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
              : const Color(0x00000000),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: widget.isDefaultAction
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }
}
