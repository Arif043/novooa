import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_state.dart';

import 'settings_section.dart';

class AiModelSettingsTab extends StatelessWidget {
  const AiModelSettingsTab({
    super.key,
    this.scrollable = true,
    this.localRuntime = false,
  });

  final bool scrollable;
  final bool localRuntime;

  @override
  Widget build(BuildContext context) {
    return _LanguageModelsSettingsContent(
      scrollable: scrollable,
      localRuntime: localRuntime,
    );
  }
}

class _LanguageModelsSettingsContent extends StatefulWidget {
  const _LanguageModelsSettingsContent({
    required this.scrollable,
    required this.localRuntime,
  });

  final bool scrollable;
  final bool localRuntime;

  @override
  State<_LanguageModelsSettingsContent> createState() =>
      _LanguageModelsSettingsContentState();
}

class _LanguageModelsSettingsContentState
    extends State<_LanguageModelsSettingsContent> {
  late final LanguageModelsSettingsCubit _cubit;
  final _connectionName = TextEditingController();
  final _baseUrl = TextEditingController();
  final _name = TextEditingController();
  final _modelId = TextEditingController();
  final _apiKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<LanguageModelsSettingsCubit>()..load();
  }

  @override
  void dispose() {
    _connectionName.dispose();
    _baseUrl.dispose();
    _name.dispose();
    _modelId.dispose();
    _apiKey.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
            },
            builder: (context, state) => _content(context, state),
          ),
    );
  }

  Widget _content(BuildContext context, LanguageModelsSettingsState state) {
    final content = SettingsSection(
      icon: Icons.auto_awesome,
      title: 'Sprachmodelle',
      description:
          'Verbinde Modelle, die Bausteine in diesem Team verwenden können.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.models.isEmpty &&
              state.status == LanguageModelsSettingsStatus.ready)
            Text(
              'Noch kein Sprachmodell verbunden.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ...state.models.map(
            (model) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.memory_outlined),
              title: Text(model.name),
              subtitle: Text(model.modelId),
            ),
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            widget.localRuntime
                ? 'Anbieter verbinden'
                : 'Sprachmodell verbinden',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<LanguageModelProvider>(
            initialValue: state.provider,
            decoration: const InputDecoration(labelText: 'Anbieter'),
            items: LanguageModelProvider.values
                .where(
                  (provider) =>
                      widget.localRuntime ||
                      provider != LanguageModelProvider.ollama,
                )
                .map(
                  (provider) => DropdownMenuItem(
                    value: provider,
                    child: Text(provider.label),
                  ),
                )
                .toList(),
            onChanged: state.isSaving
                ? null
                : (provider) {
                    if (provider != null) _cubit.updateProvider(provider);
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.provider == LanguageModelProvider.ollama) ...[
            const Text('Verwendet Ollama auf diesem Gerät.'),
            const SizedBox(height: AppSpacing.md),
          ],
          if (state.provider == LanguageModelProvider.openAiCompatible) ...[
            TextFormField(
              controller: _baseUrl,
              enabled: !state.isSaving && !state.isConnecting,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'API-Adresse',
                hintText: widget.localRuntime
                    ? 'z. B. http://host.docker.internal:11434/v1'
                    : null,
              ),
              onChanged: _cubit.updateBaseUrl,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!widget.localRuntime) ...[
            TextFormField(
              controller: _connectionName,
              enabled: !state.isSaving,
              decoration: const InputDecoration(
                labelText: 'Name der Verbindung',
              ),
              onChanged: _cubit.updateConnectionName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _name,
              enabled: !state.isSaving,
              decoration: const InputDecoration(
                labelText: 'Anzeigename des Modells',
              ),
              onChanged: _cubit.updateName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _modelId,
              enabled: !state.isSaving,
              decoration: const InputDecoration(labelText: 'Modell-ID'),
              onChanged: _cubit.updateModelId,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (state.provider != LanguageModelProvider.ollama)
            TextFormField(
              controller: _apiKey,
              enabled: !state.isSaving && !state.isConnecting,
              obscureText: true,
              decoration: InputDecoration(
                labelText:
                    widget.localRuntime &&
                        state.provider == LanguageModelProvider.openAiCompatible
                    ? 'API-Key (bei Ollama leer lassen)'
                    : 'API-Key',
              ),
              onChanged: _cubit.updateApiKey,
            ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: state.isSaving || state.isConnecting
                  ? null
                  : (widget.localRuntime ? _cubit.connect : _cubit.save),
              icon: state.isSaving || state.isConnecting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_link),
              label: Text(
                widget.localRuntime
                    ? 'Anbieter verbinden'
                    : 'Sprachmodell verbinden',
              ),
            ),
          ),
        ],
      ),
    );
    return widget.scrollable ? SingleChildScrollView(child: content) : content;
  }

  void _clearInputs() {
    _connectionName.clear();
    _baseUrl.clear();
    _name.clear();
    _modelId.clear();
    _apiKey.clear();
  }
}
