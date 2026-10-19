import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_picker_field.dart';

import '../cubits/node_language_models_cubit.dart';
import '../cubits/node_language_models_state.dart';

/// Sprachmodell eines Bausteins (oder eines Agenten darin). Ohne
/// [NodeLanguageModelsCubit] (z. B. in der Vorschau) bleibt das Feld gesperrt.
class NodeLanguageModelField extends StatelessWidget {
  const NodeLanguageModelField({
    super.key,
    required this.selectedModelId,
    required this.onChanged,
  });

  final String selectedModelId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!_hasLanguageModels(context)) {
      return LanguageModelPickerField(
        models: const [],
        selectedModelId: '',
        enabled: false,
        onChanged: (_) {},
      );
    }
    return BlocBuilder<NodeLanguageModelsCubit, NodeLanguageModelsState>(
      builder: (context, state) => LanguageModelPickerField(
        models: state.models
            .where((model) => !model.isSpeechModel)
            .toList(growable: false),
        selectedModelId: selectedModelId,
        enabled: state.status == NodeLanguageModelsStatus.ready,
        onChanged: onChanged,
      ),
    );
  }

  bool _hasLanguageModels(BuildContext context) {
    try {
      BlocProvider.of<NodeLanguageModelsCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }
}
