import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'adaptive_sheet.dart';

/// Datumsauswahl: Bottom Sheet mit Drehrad auf dem Handy, der übliche
/// Kalender-Dialog am Desktop (gleiche Entscheidung wie [showAdaptiveSheet]).
/// Liefert `null` bei Abbruch.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime minimumDate,
  required DateTime maximumDate,
}) {
  if (adaptiveSheetStyle(context).isWindow) {
    return showDatePicker(
      context: context,
      initialDate: _within(initialDate, minimumDate, maximumDate),
      firstDate: minimumDate,
      lastDate: maximumDate,
    );
  }
  var selected = initialDate;
  return _showWheelSheet<DateTime>(
    context: context,
    title: 'Datum',
    result: () => selected,
    picker: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: initialDate,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
      onDateTimeChanged: (value) => selected = value,
    ),
  );
}

/// Zeitauswahl: Bottom Sheet mit Drehrad auf dem Handy, der übliche
/// Uhrzeit-Dialog am Desktop. Liefert `null` bei Abbruch.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  if (adaptiveSheetStyle(context).isWindow) {
    return showTimePicker(context: context, initialTime: initialTime);
  }
  var selected = initialTime;
  return _showWheelSheet<TimeOfDay>(
    context: context,
    title: 'Uhrzeit',
    result: () => selected,
    picker: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      use24hFormat: true,
      initialDateTime: DateTime(
        2000,
        1,
        1,
        initialTime.hour,
        initialTime.minute,
      ),
      onDateTimeChanged: (value) {
        selected = TimeOfDay(hour: value.hour, minute: value.minute);
      },
    ),
  );
}

DateTime _within(DateTime value, DateTime minimum, DateTime maximum) {
  if (value.isBefore(minimum)) return minimum;
  if (value.isAfter(maximum)) return maximum;
  return value;
}

Future<T?> _showWheelSheet<T>({
  required BuildContext context,
  required String title,
  required T Function() result,
  required Widget picker,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => _WheelSheet(
      title: title,
      onCancel: () => Navigator.of(sheetContext).pop(),
      onConfirm: () => Navigator.of(sheetContext).pop(result()),
      picker: picker,
    ),
  );
}

class _WheelSheet extends StatelessWidget {
  const _WheelSheet({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
    required this.picker,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: SizedBox(
            height: kToolbarHeight,
            child: NavigationToolbar(
              leading: TextButton(
                onPressed: onCancel,
                child: const Text('Abbrechen'),
              ),
              middle: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: TextButton(
                onPressed: onConfirm,
                child: const Text('Fertig'),
              ),
            ),
          ),
        ),
        SizedBox(height: 216, child: picker),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
