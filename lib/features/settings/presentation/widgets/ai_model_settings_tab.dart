import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_state.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_state.dart';

import 'language_model_connect_form.dart';
import 'language_model_connected_models_section.dart';
import 'language_model_defaults_sections.dart';
import 'settings_section.dart';

class AiModelSettingsTab extends StatelessWidget {
  const AiModelSettingsTab({
    super.key,
    this.scrollable = true,
    this.isStandalone = false,
  });

  final bool scrollable;
  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    return _LanguageModelsSettingsContent(
      scrollable: scrollable,
      isStandalone: isStandalone,
    );
  }
}

class _LanguageModelsSettingsContent extends StatefulWidget {
  const _LanguageModelsSettingsContent({
    required this.scrollable,
    required this.isStandalone,
  });

  final bool scrollable;
  final bool isStandalone;

  @override
  State<_LanguageModelsSettingsContent> createState() =>
      _LanguageModelsSettingsContentState();
}

class _LanguageModelsSettingsContentState
    extends State<_LanguageModelsSettingsContent> {
  late final LanguageModelsSettingsCubit _cubit;
  late final LanguageModelDefaultsCubit _defaultsCubit;
  late final LanguageModelConnectionsCubit? _connectionsCubit;
  final _connectionName = TextEditingController();
  final _baseUrl = TextEditingController();
  final _name = TextEditingController();
  final _modelId = TextEditingController();
  final _apiKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<LanguageModelsSettingsCubit>()..load();
    _defaultsCubit = serviceLocator<LanguageModelDefaultsCubit>()..load();
    _connectionsCubit = widget.isStandalone
        ? (serviceLocator<LanguageModelConnectionsCubit>()..load())
        : null;
  }

  @override
  void dispose() {
    _connectionName.dispose();
    _baseUrl.dispose();
    _name.dispose();
    _modelId.dispose();
    _apiKey.dispose();
    _cubit.close();
    _defaultsCubit.close();
    _connectionsCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _defaultsCubit),
      ],
      child:
          BlocConsumer<
            LanguageModelsSettingsCubit,
            LanguageModelsSettingsState
          >(
            listenWhen: (previous, current) =>
                previous.message != current.message && current.message != null,
            listener: (context, state) {
              if (state.message == 'Sprachmodell verbunden.' ||
                  state.message == 'Modelle wurden verbunden.') {
                _clearInputs();
              }
              _showMessage(context, state.message!);
            },
            builder: (context, state) => _withConnectionsState(
              (connectionsState) => _content(context, state, connectionsState),
            ),
          ),
    );
  }

  Widget _withConnectionsState(
    Widget Function(LanguageModelConnectionsState?) builder,
  ) {
    final connectionsCubit = _connectionsCubit;
    if (connectionsCubit == null) return builder(null);
    return BlocProvider.value(
      value: connectionsCubit,
      child:
          BlocConsumer<
            LanguageModelConnectionsCubit,
            LanguageModelConnectionsState
          >(
            listenWhen: (previous, current) =>
                previous.message != current.message && current.message != null,
            listener: (context, state) => _showMessage(context, state.message!),
            builder: (context, connectionsState) => builder(connectionsState),
          ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _content(
    BuildContext context,
    LanguageModelsSettingsState state,
    LanguageModelConnectionsState? connectionsState,
  ) {
    final connections = connectionsState?.connections ?? const [];
    final content = SettingsSection(
      icon: Icons.auto_awesome,
      title: 'Sprachmodelle',
      description:
          'Verbinde Modelle, die Bausteine in diesem Team verwenden können.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LanguageModelConnectedModelsSection(
            state: state,
            connectionsState: connectionsState,
            connectionsCubit: _connectionsCubit,
            isStandalone: widget.isStandalone,
          ),
          const Divider(height: AppSpacing.xl),
          LanguageModelConnectForm(
            cubit: _cubit,
            state: state,
            isStandalone: widget.isStandalone,
            connections: connections,
            connectionName: _connectionName,
            baseUrl: _baseUrl,
            name: _name,
            modelId: _modelId,
            apiKey: _apiKey,
          ),
        ],
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [content, const LanguageModelDefaultsSections()],
    );
    return widget.scrollable ? SingleChildScrollView(child: body) : body;
  }

  void _clearInputs() {
    _connectionName.clear();
    _baseUrl.clear();
    _name.clear();
    _modelId.clear();
    _apiKey.clear();
  }
}
