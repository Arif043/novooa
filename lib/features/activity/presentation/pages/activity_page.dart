import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/activity_cubit.dart';
import '../cubits/activity_state.dart';
import '../widgets/approval_run_grid.dart';
import '../widgets/activity_tab_content.dart';

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
            _FilterTabs(
              filter: filter,
              onChanged: (value) => setState(() => filter = value),
            ),
            Expanded(
              child: switch (state.status) {
                ActivityLoadStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                ActivityLoadStatus.failure => ActivityFailureState(
                  message: state.message,
                ),
                ActivityLoadStatus.ready => _TabBody(
                  filter: filter,
                  state: state,
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.filter, required this.onChanged});

  final TaskActivityFilter filter;
  final ValueChanged<TaskActivityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: CupertinoSlidingSegmentedControl<TaskActivityFilter>(
        groupValue: filter,
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        children: const {
          TaskActivityFilter.approvalRequired: Text('Freigabe'),
          TaskActivityFilter.denied: Text('Abgelehnt'),
          TaskActivityFilter.running: Text('Laufend'),
          TaskActivityFilter.history: Text('Verlauf'),
        },
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.filter, required this.state});

  final TaskActivityFilter filter;
  final ActivityState state;

  @override
  Widget build(BuildContext context) {
    return switch (filter) {
      TaskActivityFilter.approvalRequired => ApprovalRunGrid(
        runs: _approvalRequiredRuns,
        emptyText: 'Keine Aufgaben warten auf Freigabe.',
      ),
      TaskActivityFilter.denied => TaskRunList(
        runs: _deniedRuns,
        emptyText: 'Keine abgelehnten Aufgaben.',
      ),
      TaskActivityFilter.running => TaskRunList(
        runs: _runningRuns,
        emptyText: 'Keine Aufgaben werden gerade ausgeführt.',
      ),
      TaskActivityFilter.history =>
        state.activities.isEmpty
            ? const ActivityEmptyState(text: 'Noch keine Aktivitäten.')
            : ActivityList(activities: state.activities),
    };
  }

  List<TaskRun> get _approvalRequiredRuns {
    return state.runs
        .where((run) => run.status == TaskRunStatus.waitingForApproval)
        .toList(growable: false);
  }

  List<TaskRun> get _deniedRuns {
    return state.runs
        .where((run) => run.status == TaskRunStatus.rejected)
        .toList(growable: false);
  }

  List<TaskRun> get _runningRuns {
    return state.runs
        .where((run) {
          return run.status == TaskRunStatus.queued ||
              run.status == TaskRunStatus.running;
        })
        .toList(growable: false);
  }
}
