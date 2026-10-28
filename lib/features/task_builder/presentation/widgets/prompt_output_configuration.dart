import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

import 'prompt_choice_field.dart';
import 'structured_field_labels.dart';
import 'structured_output_fields_editor.dart';

class PromptOutputConfiguration extends StatelessWidget {
  const PromptOutputConfiguration({
    super.key,
    required this.outputType,
    required this.choices,
    required this.structuredFields,
    required this.onChoiceChanged,
    required this.onChoiceAdded,
    required this.onChoiceRemoved,
    required this.onStructuredFieldChanged,
    required this.onStructuredFieldAdded,
    required this.onStructuredFieldRemoved,
  });

  final PromptOutputType outputType;
  final List<String> choices;
  final List<StructuredOutputField> structuredFields;
  final void Function(int index, String value) onChoiceChanged;
  final VoidCallback onChoiceAdded;
  final ValueChanged<int> onChoiceRemoved;
  final void Function(int index, StructuredOutputField field)
  onStructuredFieldChanged;
  final VoidCallback onStructuredFieldAdded;
  final ValueChanged<int> onStructuredFieldRemoved;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: _stackPanels,
        transitionBuilder: _transition,
        child: KeyedSubtree(key: ValueKey(outputType), child: _configuration()),
      ),
    );
  }

  Widget _stackPanels(Widget? current, List<Widget> previous) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [...previous, ?current],
    );
  }

  Widget _transition(Widget child, Animation<double> animation) {
    final position = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: position, child: child),
    );
  }

  Widget _configuration() {
    return switch (outputType) {
      PromptOutputType.decision => _DecisionConfiguration(
        choices: choices,
        onChanged: onChoiceChanged,
        onAdd: onChoiceAdded,
        onRemove: onChoiceRemoved,
      ),
      PromptOutputType.structured => StructuredOutputFieldsEditor(
        allowedTypes: promptFieldTypes,
        fields: structuredFields,
        onChanged: onStructuredFieldChanged,
        onAdd: onStructuredFieldAdded,
        onRemove: onStructuredFieldRemoved,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _DecisionConfiguration extends StatelessWidget {
  const _DecisionConfiguration({
    required this.choices,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> choices;
  final void Function(int index, String value) onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          LocaleKeys.ui_moegliche_antworten.tr(),
          style: SyscatTheme.taskBodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var index = 0; index < choices.length; index++)
          PromptChoiceField(
            value: choices[index],
            index: index,
            canRemove: choices.length > 1,
            onChanged: onChanged,
            onRemove: onRemove,
          ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: SyscatTheme.primaryOrange),
          label: Text(
            LocaleKeys.ui_antwort_hinzufuegen.tr(),
            style: TextStyle(color: SyscatTheme.primaryOrange),
          ),
        ),
      ],
    );
  }
}
