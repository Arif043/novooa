import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';
import 'prompt_temperature_control.dart';
import 'prompt_thinking_mode_field.dart';
import 'prompt_token_limit_field.dart';

/// Die einzelnen Felder der Generierungsoptionen; jede Änderung liefert die
/// vollständigen neuen Optionen.
class PromptGenerationOptionsFields extends StatelessWidget {
  const PromptGenerationOptionsFields({
    super.key,
    required this.options,
    required this.showContextWindow,
    required this.onChanged,
  });

  final PromptGenerationOptions options;
  final bool showContextWindow;
  final ValueChanged<PromptGenerationOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PromptTemperatureControl(
          temperature: options.temperature,
          onChanged: (value) => onChanged(options.withTemperature(value)),
        ),
        const SizedBox(height: AppSpacing.sm),
        PromptTokenLimitField(
          label: LocaleKeys.task_builder_generation_options_max_output_tokens
              .tr(),
          value: options.maxOutputTokens,
          onChanged: (value) => onChanged(options.withMaxOutputTokens(value)),
        ),
        if (showContextWindow) ...[
          const SizedBox(height: AppSpacing.md),
          PromptTokenLimitField(
            label: LocaleKeys.task_builder_generation_options_context_window
                .tr(),
            helperText: LocaleKeys
                .task_builder_generation_options_context_window_helper
                .tr(),
            value: options.contextWindow,
            onChanged: (value) => onChanged(options.withContextWindow(value)),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PromptThinkingModeField(
          value: options.thinking,
          onChanged: (mode) => onChanged(options.withThinking(mode)),
        ),
      ],
    );
  }
}
