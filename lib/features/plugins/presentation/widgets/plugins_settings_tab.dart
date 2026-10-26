import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/plugins_cubit.dart';
import '../cubits/plugins_state.dart';
import '../plugin_catalog.dart';
import 'plugin_card.dart';
import 'plugin_failure_text.dart';

/// Reiter „Plugins“ der Einstellungen: alle eingebauten Plugins mit Schalter.
class PluginsSettingsTab extends StatelessWidget {
  const PluginsSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PluginsCubit, PluginsState>(
      listenWhen: (_, current) =>
          current is PluginsLoaded && current.notice != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((state as PluginsLoaded).notice!.text)),
      ),
      builder: (context, state) => switch (state) {
        PluginsLoading() => Semantics(
          label: LocaleKeys.plugins_loading.tr(),
          child: const LinearProgressIndicator(),
        ),
        PluginsLoadFailed() => const _LoadFailure(),
        PluginsLoaded() when PluginCatalog.all.isEmpty => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(LocaleKeys.plugins_empty.tr()),
        ),
        PluginsLoaded() => _PluginList(state: state),
      },
    );
  }
}

class _PluginList extends StatelessWidget {
  const _PluginList({required this.state});

  final PluginsLoaded state;

  @override
  Widget build(BuildContext context) {
    final plugins = PluginCatalog.all;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: plugins.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (_, index) {
        final plugin = plugins[index];
        return PluginCard(
          plugin: plugin,
          isEnabled: state.isEnabled(plugin.id),
          isSwitching: state.switchingId == plugin.id,
          canSwitch: state.switchingId == null,
        );
      },
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(LocaleKeys.plugins_load_failed.tr()),
          OutlinedButton.icon(
            onPressed: context.read<PluginsCubit>().start,
            icon: const Icon(Icons.refresh),
            label: Text(LocaleKeys.plugins_retry.tr()),
          ),
        ],
      ),
    );
  }
}
