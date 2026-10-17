import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';
import 'thinking_mode_labels.dart';

class PromptThinkingModeField extends StatelessWidget {
  const PromptThinkingModeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThinkingMode value;
  final ValueChanged<ThinkingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ThinkingMode>(
      key: ValueKey(value),
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: LocaleKeys.task_builder_generation_options_thinking.tr(),
      ),
      items: [
        for (final mode in ThinkingMode.values)
          DropdownMenuItem(value: mode, child: Text(mode.localizedLabel)),
      ],
      onChanged: (mode) {
        if (mode != null) onChanged(mode);
      },
    );
  }
}
