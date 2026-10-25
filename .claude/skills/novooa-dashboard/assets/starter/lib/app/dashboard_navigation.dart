import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/runs/presentation/cubits/runs_cubit.dart';
import '../features/runs/presentation/pages/runs_page.dart';
import '../features/tasks/presentation/pages/tasks_page.dart';
import '../l10n/dashboard_keys.dart';
import 'dashboard_config.dart';

/// Unten auf dem Handy, seitlich ab Tablet-Breite.
class DashboardNavigation extends StatefulWidget {
  const DashboardNavigation({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  static const _wideLayout = 840.0;

  @override
  State<DashboardNavigation> createState() => _DashboardNavigationState();
}

class _DashboardNavigationState extends State<DashboardNavigation> {
  var _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final page = _index == 0
        ? const TasksPage()
        : RunsPage(onShowTasks: () => _select(0));
    final isWide =
        MediaQuery.sizeOf(context).width >= DashboardNavigation._wideLayout;
    return Scaffold(
      appBar: AppBar(
        title: const Text(DashboardConfig.title),
        actions: [
          IconButton(
            tooltip: DashboardKeys.signOut.tr(),
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                _Rail(index: _index, onSelect: _select),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            )
          : page,
      bottomNavigationBar: isWide
          ? null
          : _BottomBar(index: _index, onSelect: _select),
    );
  }
}

/// Wartende Läufe als Zahl am Ziel „Läufe“.
int _waitingRuns(BuildContext context) => context.select<RunsCubit, int>(
  (cubit) => switch (cubit.state) {
    RunsLoaded(:final runs) => runs.where((run) => run.needsReview).length,
    _ => 0,
  },
);

Widget _runsIcon(int waiting) => Badge.count(
  count: waiting,
  isLabelVisible: waiting > 0,
  child: const Icon(Icons.history),
);

class _Rail extends StatelessWidget {
  const _Rail({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: index,
    onDestinationSelected: onSelect,
    labelType: NavigationRailLabelType.all,
    destinations: [
      NavigationRailDestination(
        icon: const Icon(Icons.play_circle_outline),
        label: Text(DashboardKeys.tasksTitle.tr()),
      ),
      NavigationRailDestination(
        icon: _runsIcon(_waitingRuns(context)),
        label: Text(DashboardKeys.runsTitle.tr()),
      ),
    ],
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: index,
    onDestinationSelected: onSelect,
    destinations: [
      NavigationDestination(
        icon: const Icon(Icons.play_circle_outline),
        label: DashboardKeys.tasksTitle.tr(),
      ),
      NavigationDestination(
        icon: _runsIcon(_waitingRuns(context)),
        label: DashboardKeys.runsTitle.tr(),
      ),
    ],
  );
}
