import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../cubits/plugins_cubit.dart';
import '../plugin_catalog.dart';

/// Ein Plugin mit Schalter; aktiv zeigt es darunter seine Einstellungen.
class PluginCard extends StatelessWidget {
  const PluginCard({
    super.key,
    required this.plugin,
    required this.isEnabled,
    required this.isSwitching,
    required this.canSwitch,
  });

  final PluginDescription plugin;
  final bool isEnabled;
  final bool isSwitching;
  final bool canSwitch;

  @override
  Widget build(BuildContext context) {
    final settings = plugin.settingsBuilder;
    return SettingsSection(
      icon: plugin.icon,
      title: plugin.title,
      description: plugin.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isEnabled
                  ? LocaleKeys.plugins_active.tr()
                  : LocaleKeys.plugins_inactive.tr(),
            ),
            secondary: isSwitching
                ? const SizedBox.square(
                    dimension: AppSpacing.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            value: isEnabled,
            onChanged: canSwitch && !isSwitching
                ? (enabled) => _switch(context, enabled)
                : null,
          ),
          if (isEnabled && settings != null) ...[
            const SizedBox(height: AppSpacing.md),
            settings(context),
          ],
        ],
      ),
    );
  }

  Future<void> _switch(BuildContext context, bool enabled) async {
    if (!enabled && !await _confirmDisable(context)) return;
    if (!context.mounted) return;
    await context.read<PluginsCubit>().setEnabled(plugin.id, enabled: enabled);
  }

  Future<bool> _confirmDisable(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.plugins_disable_title.tr(args: [plugin.title])),
        content: SingleChildScrollView(
          child: Text(LocaleKeys.plugins_disable_message.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.plugins_cancel.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocaleKeys.plugins_disable_confirm.tr()),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
