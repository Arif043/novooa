import 'package:flutter/material.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_state.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_state.dart';

import 'language_model_connected_providers_list.dart';

/// Zeigt im Standalone-Modus die verbundenen Anbieter (gruppiert), sonst
/// (Cloud) die bisherige flache Modell-Liste — Cloud kennt kein
/// Connection-Konzept.
class LanguageModelConnectedModelsSection extends StatelessWidget {
  const LanguageModelConnectedModelsSection({
    super.key,
    required this.state,
    required this.connectionsState,
    required this.connectionsCubit,
    required this.isStandalone,
  });

  final LanguageModelsSettingsState state;
  final LanguageModelConnectionsState? connectionsState;
  final LanguageModelConnectionsCubit? connectionsCubit;
  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    final connectionsCubit = this.connectionsCubit;
    if (isStandalone && connectionsCubit != null) {
      final connections = connectionsState?.connections ?? const [];
      return LanguageModelConnectedProvidersList(
        connections: connections,
        models: state.models,
        connectionsCubit: connectionsCubit,
        isEmpty:
            connections.isEmpty &&
            connectionsState?.status == LanguageModelConnectionsStatus.ready,
      );
    }
    if (state.models.isEmpty &&
        state.status == LanguageModelsSettingsStatus.ready) {
      return Text(
        'Noch kein Sprachmodell verbunden.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: state.models
          .map(
            (model) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.memory_outlined),
              title: Text(model.name),
              subtitle: Text(model.modelId),
            ),
          )
          .toList(growable: false),
    );
  }
}
