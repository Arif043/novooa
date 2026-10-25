import 'package:flutter/material.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_state.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_state.dart';

import 'language_model_connected_providers_list.dart';

/// Die verbundenen Anbieter, gruppiert mit ihren Modellen.
class LanguageModelConnectedModelsSection extends StatelessWidget {
  const LanguageModelConnectedModelsSection({
    super.key,
    required this.state,
    required this.connectionsState,
    required this.connectionsCubit,
  });

  final LanguageModelsSettingsState state;
  final LanguageModelConnectionsState connectionsState;
  final LanguageModelConnectionsCubit connectionsCubit;

  @override
  Widget build(BuildContext context) {
    final connections = connectionsState.connections;
    return LanguageModelConnectedProvidersList(
      connections: connections,
      models: state.models,
      connectionsCubit: connectionsCubit,
      isEmpty:
          connections.isEmpty &&
          connectionsState.status == LanguageModelConnectionsStatus.ready,
    );
  }
}
