import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/settings/presentation/widgets/settings_section.dart';

import '../../domain/entities/installed_plugin.dart';
import '../../domain/entities/plugin_catalog_entry.dart';
import '../../domain/entities/plugin_manifest.dart';
import '../cubits/plugin_catalog_cubit.dart';
import '../cubits/plugin_catalog_state.dart';
import '../cubits/plugin_install_cubit.dart';
import '../cubits/plugin_install_state.dart';
import '../cubits/plugins_cubit.dart';
import '../cubits/plugins_state.dart';
import 'plugin_icons.dart';
import 'plugin_settings_panels.dart';

/// Tab „Plugins“ in den Runtime-Einstellungen (nur Standalone): installierte
/// Plugins mit ihren Einstellungs-Panels, Katalog und Installation.
class PluginsSettingsTab extends StatelessWidget {
  const PluginsSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<PluginsCubit>()..load()),
        BlocProvider(create: (_) => serviceLocator<PluginInstallCubit>()),
        BlocProvider(
          create: (_) => serviceLocator<PluginCatalogCubit>()..load(),
        ),
      ],
      child: BlocListener<PluginInstallCubit, PluginInstallState>(
        listener: (context, state) {
          final message = switch (state) {
            PluginInstallDone(:final name) => 'Plugin „$name“ installiert.',
            PluginInstallFailed(:final message) => message,
            _ => null,
          };
          if (message == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          context.read<PluginInstallCubit>().reset();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            _InstalledSection(),
            SizedBox(height: AppSpacing.lg),
            _InstallSection(),
          ],
        ),
      ),
    );
  }
}

class _InstalledSection extends StatelessWidget {
  const _InstalledSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.extension_outlined,
      title: 'Installierte Plugins',
      description:
          'Plugins ergänzen Bausteine, Trigger und Einstellungen. '
          'Sie laufen in dieser Runtime.',
      child: BlocConsumer<PluginsCubit, PluginsState>(
        listenWhen: (previous, current) =>
            current.message != null && current.message != previous.message,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
          context.read<PluginsCubit>().messageShown();
        },
        builder: (context, state) {
          if (state.status == PluginsStatus.loading) {
            return const LinearProgressIndicator();
          }
          if (state.plugins.isEmpty) {
            return const Text(
              'Noch keine Plugins installiert. Wähle unten eines aus dem '
              'Katalog oder installiere eine ZIP-Datei.',
            );
          }
          return Column(
            children: [
              for (final plugin in state.plugins) _PluginTile(plugin: plugin),
            ],
          );
        },
      ),
    );
  }
}

class _PluginTile extends StatelessWidget {
  const _PluginTile({required this.plugin});

  final InstalledPlugin plugin;

  @override
  Widget build(BuildContext context) {
    final manifest = plugin.manifest;
    return ExpansionTile(
      key: ValueKey('plugin-${plugin.id}'),
      leading: const Icon(Icons.extension_outlined),
      title: Text('${plugin.name} ${plugin.version}'),
      subtitle: Text(_summary(manifest)),
      childrenPadding: const EdgeInsets.all(AppSpacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plugin.description.isNotEmpty) Text(plugin.description),
        const SizedBox(height: AppSpacing.md),
        PluginSettingsPanels(manifest: manifest),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Deinstallieren'),
            onPressed: () => _confirmUninstall(context),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmUninstall(BuildContext context) async {
    final cubit = context.read<PluginsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('„${plugin.name}“ deinstallieren?'),
        content: const Text(
          'Aufgaben, die Bausteine dieses Plugins nutzen, überspringen sie '
          'danach. Die Einstellungen des Plugins werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deinstallieren'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.uninstall(plugin.id);
  }
}

String _summary(PluginManifest manifest) {
  final primitives = manifest.primitives.length;
  final panels = manifest.settingsPanels.length;
  final parts = [
    if (primitives > 0) '$primitives Baustein${primitives == 1 ? '' : 'e'}',
    if (manifest.triggers.isNotEmpty) '${manifest.triggers.length} Trigger',
    if (panels > 0) '$panels Einstellungs-Panel${panels == 1 ? '' : 's'}',
  ];
  return parts.isEmpty ? 'Enthält keine Erweiterungen.' : parts.join(' · ');
}

class _InstallSection extends StatelessWidget {
  const _InstallSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.download_outlined,
      title: 'Plugin installieren',
      description:
          'Nur vom Herausgeber signierte Plugins werden installiert. '
          'Du siehst vorab, was ein Plugin mitbringt.',
      child: BlocBuilder<PluginInstallCubit, PluginInstallState>(
        builder: (context, state) => switch (state) {
          PluginInstallChecking() => const LinearProgressIndicator(),
          PluginInstallReview(:final preview) => _Review(
            preview: preview,
            installing: false,
          ),
          PluginInstallInstalling(:final preview) => _Review(
            preview: preview,
            installing: true,
          ),
          _ => const _CatalogAndArchive(),
        },
      ),
    );
  }
}

class _CatalogAndArchive extends StatelessWidget {
  const _CatalogAndArchive();

  @override
  Widget build(BuildContext context) {
    final installed = context.select<PluginsCubit, Map<String, String>>(
      (cubit) => {
        for (final plugin in cubit.state.plugins) plugin.id: plugin.version,
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<PluginCatalogCubit, PluginCatalogState>(
          builder: (context, state) => switch (state.status) {
            PluginCatalogStatus.loading => const LinearProgressIndicator(),
            PluginCatalogStatus.failure => Text(
              state.message ?? 'Der Katalog ist nicht verfügbar.',
            ),
            PluginCatalogStatus.ready when state.entries.isEmpty => const Text(
              'Der Katalog enthält noch keine Plugins.',
            ),
            PluginCatalogStatus.ready => Column(
              children: [
                for (final entry in state.entries)
                  _CatalogTile(
                    entry: entry,
                    installedVersion: installed[entry.id],
                  ),
              ],
            ),
          },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.folder_zip_outlined),
          label: const Text('Aus ZIP-Datei installieren …'),
          onPressed: context.read<PluginInstallCubit>().pickArchive,
        ),
      ],
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.entry, required this.installedVersion});

  final PluginCatalogEntry entry;
  final String? installedVersion;

  @override
  Widget build(BuildContext context) {
    final upToDate = installedVersion == entry.version;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.extension_outlined),
      title: Text('${entry.name} ${entry.version}'),
      subtitle: Text(entry.description),
      trailing: FilledButton.tonal(
        onPressed: upToDate
            ? null
            : () => context.read<PluginInstallCubit>().previewCatalogEntry(
                entry.id,
              ),
        child: Text(
          upToDate
              ? 'Installiert'
              : installedVersion == null
              ? 'Installieren'
              : 'Aktualisieren',
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.preview, required this.installing});

  final PluginInstallPreview preview;
  final bool installing;

  @override
  Widget build(BuildContext context) {
    final manifest = preview.manifest;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${manifest.name} ${manifest.version}',
          style: textTheme.titleMedium,
        ),
        if (preview.isUpdate)
          Text('Ersetzt Version ${preview.installedVersion}.'),
        const SizedBox(height: AppSpacing.sm),
        Text(manifest.description),
        const SizedBox(height: AppSpacing.md),
        Text('Bringt mit:', style: textTheme.labelLarge),
        for (final primitive in manifest.primitives)
          _Item(
            icon: pluginIconFor(primitive.icon),
            text: 'Baustein „${primitive.label}“',
          ),
        for (final trigger in manifest.triggers)
          _Item(icon: Icons.bolt, text: 'Trigger „${trigger.label}“'),
        for (final panel in manifest.settingsPanels)
          _Item(
            icon: pluginIconFor(panel.icon),
            text: 'Einstellungen „${panel.title}“',
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: installing
                  ? null
                  : context.read<PluginInstallCubit>().reset,
              child: const Text('Abbrechen'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: installing
                  ? null
                  : context.read<PluginInstallCubit>().confirm,
              child: Text(
                installing
                    ? 'Installiert …'
                    : preview.isUpdate
                    ? 'Aktualisieren'
                    : 'Installieren',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
