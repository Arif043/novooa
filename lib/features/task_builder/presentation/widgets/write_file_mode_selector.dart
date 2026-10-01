import 'package:flutter/material.dart';

enum WriteTargetMode { existing, fresh }

class WriteFileModeSelector extends StatelessWidget {
  const WriteFileModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final WriteTargetMode value;
  final ValueChanged<Set<WriteTargetMode>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<WriteTargetMode>(
      segments: const [
        ButtonSegment(
          value: WriteTargetMode.existing,
          label: Text('Bestehend'),
        ),
        ButtonSegment(value: WriteTargetMode.fresh, label: Text('Neu')),
      ],
      selected: {value},
      onSelectionChanged: onChanged,
    );
  }
}
