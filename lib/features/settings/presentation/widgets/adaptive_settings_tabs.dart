import 'package:flutter/material.dart';

import 'compact_settings_navigation.dart';
import 'settings_segmented_tabs.dart';
import 'settings_tab_contribution.dart';

/// Unterhalb dieser Breite passen die Reiter nicht mehr lesbar
/// nebeneinander; dort führt eine Liste zu den einzelnen Bereichen.
const double compactSettingsMaxWidth = 600;

class AdaptiveSettingsTabs extends StatelessWidget {
  const AdaptiveSettingsTabs({super.key, required this.tabs});

  final List<SettingsTabContribution> tabs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < compactSettingsMaxWidth
          ? CompactSettingsNavigation(tabs: tabs)
          : SettingsSegmentedTabs(tabs: tabs),
    );
  }
}
