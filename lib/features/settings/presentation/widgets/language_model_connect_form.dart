import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_provider.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_state.dart';

import 'package:syscat2/features/language_models/presentation/widgets/language_model_provider_logo.dart';

/// Formular „Anbieter verbinden“. Blendet im Dropdown bereits verbundene
/// „direkte" Anbieter aus
/// (fester Endpunkt, z. B. Google AI) — `openAiCompatible` bleibt immer
/// wählbar, da es mehrfach mit unterschiedlichen Endpunkten verbunden werden
/// kann.
class LanguageModelConnectForm extends StatelessWidget {
  const LanguageModelConnectForm({
    super.key,
    required this.cubit,
    required this.state,
    required this.connections,
    required this.baseUrl,
    required this.apiKey,
  });

  final LanguageModelsSettingsCubit cubit;
  final LanguageModelsSettingsState state;
  final List<LanguageModelConnection> connections;
  final TextEditingController baseUrl;
  final TextEditingController apiKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Anbieter verbinden',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _providerDropdown(context),
        const SizedBox(height: AppSpacing.md),
        if (state.provider == LanguageModelProvider.ollama) ...[
          const Text('Verwendet Ollama auf diesem Gerät.'),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.provider == LanguageModelProvider.openAiCompatible) ...[
          _baseUrlField(),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.provider != LanguageModelProvider.ollama) _apiKeyField(),
        const SizedBox(height: AppSpacing.lg),
        _submitButton(),
      ],
    );
  }

  Widget _providerDropdown(BuildContext context) {
    final selectable = _selectableProviders();
    final displayedProvider = selectable.contains(state.provider)
        ? state.provider
        : (selectable.isEmpty ? null : selectable.first);
    // Der zuletzt gewählte Anbieter kann durch eine neue Verbindung
    // (z. B. per anderem Gerät) zwischenzeitlich ausgeblendet worden sein.
    // Statt abzustürzen (DropdownButtonFormField verlangt exakt einen
    // Treffer für seinen Anfangswert), weichen wir für diesen Frame auf den
    // ersten verfügbaren Anbieter aus und gleichen den Cubit-Zustand direkt
    // danach ab, damit „Verbinden" nie einen unsichtbar gewählten Anbieter
    // sendet.
    if (displayedProvider != null && displayedProvider != state.provider) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => cubit.updateProvider(displayedProvider),
      );
    }
    return DropdownButtonFormField<LanguageModelProvider>(
      initialValue: displayedProvider,
      decoration: const InputDecoration(labelText: 'Anbieter'),
      items: selectable
          .map(
            (provider) => DropdownMenuItem(
              value: provider,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  providerLogo(
                    context,
                    provider: provider,
                    size: AppSpacing.md,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(provider.label),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: state.isConnecting
          ? null
          : (provider) {
              if (provider != null) cubit.updateProvider(provider);
            },
    );
  }

  Widget _baseUrlField() {
    return TextFormField(
      controller: baseUrl,
      enabled: !state.isConnecting,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'API-Adresse',
        hintText: 'z. B. http://host.docker.internal:11434/v1',
      ),
      onChanged: cubit.updateBaseUrl,
    );
  }

  Widget _apiKeyField() {
    return TextFormField(
      controller: apiKey,
      enabled: !state.isConnecting,
      obscureText: true,
      decoration: InputDecoration(
        labelText: state.provider == LanguageModelProvider.openAiCompatible
            ? 'API-Key (bei Ollama leer lassen)'
            : 'API-Key',
      ),
      onChanged: cubit.updateApiKey,
    );
  }

  Widget _submitButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: state.isConnecting ? null : cubit.connect,
        icon: state.isConnecting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_link),
        label: const Text('Anbieter verbinden'),
      ),
    );
  }

  List<LanguageModelProvider> _selectableProviders() {
    return LanguageModelProvider.values
        .where((provider) {
          if (!provider.isDirectProvider) return true;
          return !connections.any(
            (connection) => connection.provider == provider,
          );
        })
        .toList(growable: false);
  }
}
