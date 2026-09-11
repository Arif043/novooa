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

Future<DateTime?> showIosDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime minimumDate,
  required DateTime maximumDate,
}) {
  var selectedDate = initialDate;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (popupContext) => _IosPickerSheet(
      onCancel: () => Navigator.of(popupContext).pop(),
      onConfirm: () => Navigator.of(popupContext).pop(selectedDate),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initialDate,
        minimumDate: minimumDate,
        maximumDate: maximumDate,
        onDateTimeChanged: (value) => selectedDate = value,
      ),
    ),
  );
}

Future<TimeOfDay?> showIosTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  var selectedTime = initialTime;
  return showCupertinoModalPopup<TimeOfDay>(
    context: context,
    builder: (popupContext) => _IosPickerSheet(
      onCancel: () => Navigator.of(popupContext).pop(),
      onConfirm: () => Navigator.of(popupContext).pop(selectedTime),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: DateTime(
          2000,
          1,
          1,
          initialTime.hour,
          initialTime.minute,
        ),
        onDateTimeChanged: (value) {
          selectedTime = TimeOfDay(hour: value.hour, minute: value.minute);
        },
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

class _IosPickerSheet extends StatelessWidget {
  const _IosPickerSheet({
    required this.child,
    required this.onCancel,
    required this.onConfirm,
  });

  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: CupertinoPopupSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: onCancel,
                  child: const Text('Abbrechen'),
                ),
                CupertinoButton(
                  onPressed: onConfirm,
                  child: const Text('Fertig'),
                ),
              ],
            ),
            SizedBox(height: 216, child: child),
          ],
        ),
      ),
    );
  }
}
