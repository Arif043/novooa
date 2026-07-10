import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_activity.dart';
import '../cubits/activity_cubit.dart';
import '../cubits/activity_state.dart';
import '../widgets/activity_tile.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => serviceLocator<ActivityCubit>()..load(), child: const _ActivityView());
  }
}

enum TaskActivityFilter { approvalRequired, denied, running, history }

class _ActivityView extends StatefulWidget {
  const _ActivityView();

  @override
  State<_ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_ActivityView> {
  var filter = TaskActivityFilter.approvalRequired;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        return Column(
          children: [
            CupertinoSlidingSegmentedControl<TaskActivityFilter>(
              groupValue: filter,
              onValueChanged: (TaskActivityFilter? value) {
                if (value != null) {
                  setState(() {
                    filter = value;
                  });
                }
              },
              children: <TaskActivityFilter, Widget>{
                TaskActivityFilter.approvalRequired: const Text('Freigabe erforderlich'),
                TaskActivityFilter.denied: const Text('Abgelehnt'),
                TaskActivityFilter.running: const Text('Wird ausgeführt'),
                TaskActivityFilter.history: const Text('Verlauf'),
              },
            ),
            Expanded(
              child: switch (state.status) {
                ActivityLoadStatus.loading => const Center(child: CircularProgressIndicator()),
                ActivityLoadStatus.failure => _FailureState(message: state.message),
                ActivityLoadStatus.ready when state.activities.isEmpty => const _EmptyState(),
                ActivityLoadStatus.ready => _ActivityList(activities: state.activities),
              },
            ),
          ],
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<TaskActivity> activities;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<ActivityCubit>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: activities.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          return ActivityTile(activity: activities[index]);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Noch keine Aktivitäten. Führe eine Aufgabe aus.'),
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? 'Aktivitäten konnten nicht geladen werden.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: context.read<ActivityCubit>().load,
              icon: const Icon(Icons.refresh),
              label: Text('Erneut versuchen', style: textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}
