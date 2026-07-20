import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/task.dart';
import '../cubits/task_homepage_cubit.dart';
import '../widgets/task_tile.dart';

class TaskHomepage extends StatelessWidget {
  const TaskHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<TaskHomepageCubit>()..load(),
      child: const _TaskHomepageView(),
    );
  }
}

class _TaskHomepageView extends StatelessWidget {
  const _TaskHomepageView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TaskHomepageHeader(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BlocBuilder<TaskHomepageCubit, TaskHomepageState>(
              builder: (context, state) => _TaskHomepageBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskHomepageHeader extends StatelessWidget {
  const _TaskHomepageHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: () => context.go('/tasks/builder'),
          icon: const Icon(Icons.add),
          label: const Text('Neue Aufgabe'),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: ColorScheme.of(context).onSecondary,
            backgroundColor: ColorScheme.of(context).secondary,
          ),
          onPressed: () => context.go('/tasks/builder'),
          child: const Text('Aus Vorlage'),
        ),
      ],
    );
  }
}

class _TaskHomepageBody extends StatelessWidget {
  const _TaskHomepageBody({required this.state});

  final TaskHomepageState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TaskHomepageLoading() => const Center(child: CircularProgressIndicator()),
      TaskHomepageFailure(:final message) => _TaskFailureState(
        message: message,
      ),
      TaskHomepageReady(:final tasks) when tasks.isEmpty =>
        const _TaskEmptyState(),
      TaskHomepageReady(:final tasks) => _TaskGrid(tasks: tasks),
    };
  }
}

class _TaskGrid extends StatelessWidget {
  const _TaskGrid({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: tasks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCountFor(constraints.maxWidth),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            // childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) => TaskTile(task: tasks[index]),
        );
      },
    );
  }

  int _columnCountFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }
}

class _TaskEmptyState extends StatelessWidget {
  const _TaskEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.go('/tasks/builder'),
        icon: const Icon(Icons.add),
        label: const Text('Erste Aufgabe erstellen'),
      ),
    );
  }
}

class _TaskFailureState extends StatelessWidget {
  const _TaskFailureState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: context.read<TaskHomepageCubit>().load,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
