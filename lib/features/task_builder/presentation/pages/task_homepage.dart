import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/responsive_card_grid.dart';

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
      padding: const EdgeInsets.only(
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        bottom: AppSpacing.xxl,
        top: AppSpacing.md,
      ),
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
          label: Text(LocaleKeys.ui_neue_aufgabe.tr()),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(
            foregroundColor: ColorScheme.of(context).onSecondary,
            backgroundColor: ColorScheme.of(context).secondary,
          ),
          onPressed: () => context.go('/tasks/builder'),
          child: Text(LocaleKeys.ui_aus_vorlage.tr()),
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
    return ResponsiveCardGrid(
      children: [
        for (final task in tasks) TaskTile(key: ValueKey(task.id), task: task),
      ],
    );
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
        label: Text(LocaleKeys.ui_erste_aufgabe_erstellen.tr()),
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
            child: Text(LocaleKeys.ui_erneut_versuchen.tr()),
          ),
        ],
      ),
    );
  }
}
