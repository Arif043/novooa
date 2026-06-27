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
    return BlocProvider(
      create: (_) => serviceLocator<ActivityCubit>()..load(),
      child: const _ActivityView(),
    );
  }
}

class _ActivityView extends StatelessWidget {
  const _ActivityView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) => _ActivityBody(state: state),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody({required this.state});

  final ActivityState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ActivityLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ActivityLoadStatus.failure => _FailureState(message: state.message),
      ActivityLoadStatus.ready when state.activities.isEmpty =>
        const _EmptyState(),
      ActivityLoadStatus.ready => _ActivityList(activities: state.activities),
    };
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
