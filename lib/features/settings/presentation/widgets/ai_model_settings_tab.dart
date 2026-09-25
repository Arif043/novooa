import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_models_settings_state.dart';

import 'settings_section.dart';

/// Markenlogo je Anbieter — einheitlich einfarbig (`onSurfaceVariant`),
/// passend zum zurückhaltenden Icon-Stil des restlichen Studios.
/// `googleAi`/`mistral`/`openRouter`/`ollama` kommen aus `package:simple_icons`
/// (CC0-lizenziert). Für `xAi` gibt es dort kein Icon und `openAiCompatible`
/// steht stellvertretend für den generischen OpenAI-Modus — beide werden
/// stattdessen aus den mitgelieferten SVGs gerendert (`fill="currentColor"`,
/// daher über [SvgTheme.currentColor] eingefärbt statt fest verdrahtet).
Widget _providerLogo(
  BuildContext context, {
  required LanguageModelProvider provider,
  required double size,
}) {
  final color = Theme.of(context).colorScheme.onSurfaceVariant;
  final svgAsset = switch (provider) {
    LanguageModelProvider.xAi => 'assets/icons/xai.svg',
    LanguageModelProvider.openAiCompatible => 'assets/icons/openai.svg',
    _ => null,
  };
  if (svgAsset != null) {
    return SvgPicture.asset(
      svgAsset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      // Falls die gebündelte SVG-Datei fehlt oder ungültig ist, lieber das
      // neutrale Platzhalter-Icon zeigen als das Dropdown abstürzen zu
      // lassen.
      errorBuilder: (context, error, stackTrace) =>
          Icon(_providerIconData(provider), size: size, color: color),
    );
  }
  return Icon(_providerIconData(provider), size: size, color: color);
}

IconData _providerIconData(LanguageModelProvider provider) {
  return switch (provider) {
    LanguageModelProvider.googleAi => SimpleIcons.googlegemini,
    LanguageModelProvider.mistral => SimpleIcons.mistralai,
    LanguageModelProvider.openRouter => SimpleIcons.openrouter,
    LanguageModelProvider.ollama => SimpleIcons.ollama,
    LanguageModelProvider.xAi ||
    LanguageModelProvider.openAiCompatible => Icons.smart_toy_outlined,
  };
}

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
            widget.isStandalone
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
                      widget.isStandalone ||
                      provider != LanguageModelProvider.ollama,
                )
                .map(
                  (provider) => DropdownMenuItem(
                    value: provider,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _providerLogo(
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
                hintText: widget.isStandalone
                    ? 'z. B. http://host.docker.internal:11434/v1'
                    : null,
              ),
              onChanged: _cubit.updateBaseUrl,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!widget.isStandalone) ...[
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
                    widget.isStandalone &&
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
                  : (widget.isStandalone ? _cubit.connect : _cubit.save),
              icon: state.isSaving || state.isConnecting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_link),
              label: Text(
                widget.isStandalone
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
