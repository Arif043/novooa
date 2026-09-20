import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Keeps all labels accessible when large text no longer fits a segment.
class ScheduleChoiceControl<T extends Object> extends StatelessWidget {
  const ScheduleChoiceControl({
    super.key,
    required this.value,
    required this.labels,
    required this.onChanged,
    required this.label,
  });
  final T value;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 320 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: labels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        );
      }
      final colors = Theme.of(context).colorScheme;
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: colors.surfaceContainerLow,
        thumbColor: colors.surface,
        children: labels.map(
          (key, text) => MapEntry(
            key,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: key == value
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontWeight: key == value ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
      );
    },
  );
}
