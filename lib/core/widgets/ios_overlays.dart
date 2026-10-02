import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<T?> showIosDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => Material(
      type: MaterialType.transparency,
      child: builder(dialogContext),
    ),
  );
}

Future<T?> showIosActionSheet<T>({
  required BuildContext context,
  required List<IosAction<T>> actions,
  String? title,
  String? message,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (popupContext) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: actions
          .map(
            (action) => CupertinoActionSheetAction(
              isDestructiveAction: action.isDestructive,
              onPressed: () => Navigator.of(popupContext).pop(action.value),
              child: Text(action.label),
            ),
          )
          .toList(growable: false),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(popupContext).pop(),
        child: const Text('Abbrechen'),
      ),
    ),
  );
}

Future<T?> showIosSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (popupContext) => SafeArea(
      top: false,
      child: CupertinoPopupSurface(
        child: Material(
          color: Theme.of(popupContext).colorScheme.surface,
          child: builder(popupContext),
        ),
      ),
    ),
  );
}

class IosAction<T> {
  const IosAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final bool isDestructive;
}
