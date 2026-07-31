import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class SettingsFilterTabs extends StatelessWidget {
  const SettingsFilterTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CupertinoSlidingSegmentedControl<SettingsDestination>(
          groupValue: SettingsDestination.values[tabController.index],
          onValueChanged: (destination) => _select(tabController, destination),
          children: {
            for (final destination in SettingsDestination.values)
              destination: _SettingsTabLabel(destination: destination),
          },
        ),
      ),
    );
  }

  void _select(TabController controller, SettingsDestination? destination) {
    if (destination == null) return;
    controller.animateTo(destination.index);
  }
}

class _SettingsTabLabel extends StatelessWidget {
  const _SettingsTabLabel({required this.destination});

  final SettingsDestination destination;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(destination.icon),
        const SizedBox(width: AppSpacing.sm),
        Text(destination.label),
      ],
    );
  }
}

enum SettingsDestination {
  profile('Profil', CupertinoIcons.person_crop_circle),
  team('Team', CupertinoIcons.person_2),
  aiModel('Sprachmodell', CupertinoIcons.sparkles),
  communication('Kommunikation', CupertinoIcons.chat_bubble_2);

  const SettingsDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
