import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'settings_tab_contribution.dart';

/// Reiterleiste für Tablet und Desktop.
class SettingsSegmentedTabs extends StatelessWidget {
  const SettingsSegmentedTabs({super.key, required this.tabs});

  final List<SettingsTabContribution> tabs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          _SegmentedTabBar(tabs: tabs),
          Expanded(
            child: TabBarView(
              children: [for (final tab in tabs) tab.builder(context)],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({required this.tabs});

  final List<SettingsTabContribution> tabs;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: controller.index,
          onValueChanged: (selection) {
            if (selection != null) controller.animateTo(selection);
          },
          children: {
            for (final (index, tab) in tabs.indexed)
              index: _SegmentLabel(tab: tab),
          },
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.tab});

  final SettingsTabContribution tab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(tab.icon),
        const SizedBox(width: AppSpacing.sm),
        Text(tab.labelKey.tr()),
      ],
    );
  }
}
