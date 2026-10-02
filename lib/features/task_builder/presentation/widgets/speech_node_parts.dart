import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_picker_field.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../cubits/node_language_models_cubit.dart';
import '../cubits/node_language_models_state.dart';

class SpeechNodePanel extends StatelessWidget {
  const SpeechNodePanel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Sprachmodell-Wahl eines Sprachbausteins; „Lokales Modell (ONNX)" ist die
/// Option ohne Sprachmodell. Die Auswahl ist bewusst nicht gefiltert.
class SpeechLanguageModelChoice extends StatelessWidget {
  const SpeechLanguageModelChoice({
    super.key,
    required this.selectedModelId,
    required this.onChanged,
  });

  final String selectedModelId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!_hasLanguageModelsProvider(context)) {
      return _picker(context, const [], false);
    }
    return BlocBuilder<NodeLanguageModelsCubit, NodeLanguageModelsState>(
      builder: (context, state) => _picker(
        context,
        state.models,
        state.status == NodeLanguageModelsStatus.ready,
      ),
    );
  }

  Widget _picker(
    BuildContext context,
    List<LanguageModel> models,
    bool enabled,
  ) {
    return LanguageModelPickerField(
      models: models,
      selectedModelId: selectedModelId,
      enabled: enabled,
      defaultOptionLabel: 'Lokales Modell (ONNX)',
      onChanged: onChanged,
    );
  }

  bool _hasLanguageModelsProvider(BuildContext context) {
    try {
      BlocProvider.of<NodeLanguageModelsCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}
