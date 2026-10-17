import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';
import 'prompt_generation_options_fields.dart';

/// Generierungsoptionen des Prompt-Bausteins, eingeklappt unter „Erweitert“,
/// damit der Baustein für die meisten Aufgaben übersichtlich bleibt.
class PromptGenerationOptionsSection extends StatelessWidget {
  const PromptGenerationOptionsSection({
    super.key,
    required this.options,
    required this.showContextWindow,
    required this.onChanged,
  });

  final PromptGenerationOptions options;

  /// Nur Ollama kennt ein einstellbares Kontextfenster. Ein schon gesetzter
  /// Wert bleibt sichtbar, damit er sich nach einem Modellwechsel entfernen
  /// lässt.
  final bool showContextWindow;
  final ValueChanged<PromptGenerationOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    // Eigenes Material, weil das Panel einen Hintergrund hat und das ListTile
    // im ExpansionTile sonst auf dem falschen Material zeichnet.
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        initiallyExpanded: !options.usesModelDefaults,
        title: Text(LocaleKeys.task_builder_generation_options_title.tr()),
        subtitle: Text(_summary()),
        children: [
          PromptGenerationOptionsFields(
            options: options,
            showContextWindow:
                showContextWindow || options.contextWindow != null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _summary() {
    return options.usesModelDefaults
        ? LocaleKeys.task_builder_generation_options_summary_defaults.tr()
        : LocaleKeys.task_builder_generation_options_summary_custom.tr();
  }
}
