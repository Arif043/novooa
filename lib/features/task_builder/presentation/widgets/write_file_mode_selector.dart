import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
      segments: [
        ButtonSegment(
          value: WriteTargetMode.existing,
          label: Text(LocaleKeys.ui_bestehend.tr()),
        ),
        ButtonSegment(
          value: WriteTargetMode.fresh,
          label: Text(LocaleKeys.ui_neu.tr()),
        ),
      ],
      selected: {value},
      onSelectionChanged: onChanged,
    );
  }
}
