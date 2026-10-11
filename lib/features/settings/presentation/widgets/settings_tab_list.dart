import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'settings_tab_contribution.dart';

class SettingsTabList extends StatelessWidget {
  const SettingsTabList({
    super.key,
    required this.tabs,
    required this.onSelected,
  });

  final List<SettingsTabContribution> tabs;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, tab) in tabs.indexed)
                _SettingsTabTile(tab: tab, onTap: () => onSelected(index)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTabTile extends StatelessWidget {
  const _SettingsTabTile({required this.tab, required this.onTap});

  final SettingsTabContribution tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(tab.icon, color: colorScheme.primary),
      title: Text(tab.labelKey.tr()),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
