import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/schedule_cubit.dart';
import '../cubits/schedule_state.dart';
import '../widgets/create_schedule_trigger_dialog.dart';
import '../widgets/task_trigger_grid.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<ScheduleCubit>()..load(),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  const _ScheduleView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ScheduleHeader(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              builder: (context, state) => _ScheduleBody(state: state),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Zeitplan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        FilledButton.icon(
          onPressed: () => _showDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Trigger hinzufügen'),
        ),
      ],
    );
  }

  void _showDialog(BuildContext context) {
    final cubit = context.read<ScheduleCubit>();
    CreateScheduleTriggerDialog.show(
      context,
      tasks: cubit.state.tasks,
      cubit: cubit,
    );
  }
}

class _ScheduleBody extends StatelessWidget {
  const _ScheduleBody({required this.state});

  final ScheduleState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ScheduleStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ScheduleStatus.failure => _ScheduleFailureState(
        message: state.message ?? 'Zeitpläne konnten nicht geladen werden.',
      ),
      ScheduleStatus.ready when state.tasks.isEmpty => const _NoTasksState(),
      ScheduleStatus.ready when state.triggers.isEmpty =>
        const _NoTriggersState(),
      ScheduleStatus.ready => TaskTriggerGrid(
        triggers: state.triggers,
        cubit: context.read<ScheduleCubit>(),
      ),
    };
  }
}

class _NoTasksState extends StatelessWidget {
  const _NoTasksState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Erstelle zuerst eine Aufgabe, bevor du Trigger anlegst.'),
    );
  }
}

class _NoTriggersState extends StatelessWidget {
  const _NoTriggersState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Noch keine Trigger eingerichtet.'));
  }
}

class _ScheduleFailureState extends StatelessWidget {
  const _ScheduleFailureState({required this.message});

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
            onPressed: context.read<ScheduleCubit>().load,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
