import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_provider_logo.dart';

import 'language_model_picker_sheet.dart';

/// Feld „Sprachmodell": zeigt die aktuelle Wahl und öffnet das zweistufige
/// Auswahl-Sheet (Anbieter, dann Modell).
class LanguageModelPickerField extends StatelessWidget {
  const LanguageModelPickerField({
    super.key,
    required this.models,
    required this.selectedModelId,
    required this.onChanged,
    this.enabled = true,
    this.defaultOptionLabel = defaultLanguageModelLabel,
  });

  final List<LanguageModel> models;
  final String selectedModelId;
  final ValueChanged<String> onChanged;
  final bool enabled;

  /// Beschriftung der Option ohne bestimmtes Modell (leere ID).
  final String defaultOptionLabel;

  LanguageModel? get _selected {
    for (final model in models) {
      if (model.id == selectedModelId) return model;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _valueLabel();
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Sprachmodell: $label. Auswahl öffnen',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: enabled ? () => _open(context) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Sprachmodell',
            enabled: enabled,
          ),
          child: Row(
            children: [
              if (_selected?.provider case final provider?) ...[
                providerLogo(context, provider: provider, size: AppSpacing.md),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.unfold_more),
            ],
          ),
        ),
      ),
    );
  }

  String _valueLabel() {
    final model = _selected;
    if (model == null) return defaultOptionLabel;
    final provider = model.provider;
    return provider == null ? model.name : '${model.name} · ${provider.label}';
  }

  Future<void> _open(BuildContext context) async {
    final picked = await LanguageModelPickerSheet.show(
      context,
      models: models,
      selectedModelId: _selected?.id ?? defaultLanguageModelId,
      defaultOptionLabel: defaultOptionLabel,
    );
    if (picked != null && picked != _selected?.id) onChanged(picked);
  }
}
