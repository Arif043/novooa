import 'package:syscat2/features/runtime_users/presentation/cubits/current_runtime_user_cubit.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/activity_cubit.dart';
import '../cubits/activity_state.dart';
import '../widgets/approval_run_grid.dart';
import '../widgets/task_run_interaction_dialog.dart';
import '../widgets/activity_tab_content.dart';
import '../widgets/task_activity_history.dart';
import '../../../application_logs/presentation/widgets/runtime_application_logs_view.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({
    super.key,
    this.initialRunId,
    this.notificationOpenId,
    this.isStandalone = false,
  });

  final String? initialRunId;
  final String? notificationOpenId;
  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<ActivityCubit>()..load(),
      child: _ActivityView(
        initialRunId: initialRunId,
        notificationOpenId: notificationOpenId,
        isStandalone: isStandalone,
      ),
    );
  }
}

enum TaskActivityFilter { approvalRequired, denied, running, history, protocol }

class _ActivityView extends StatefulWidget {
  const _ActivityView({
    this.initialRunId,
    this.notificationOpenId,
    required this.isStandalone,
  });

  final String? initialRunId;
  final String? notificationOpenId;
  final bool isStandalone;

  @override
  State<_ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<_ActivityView> {
  var filter = TaskActivityFilter.approvalRequired;
  var _openedInitialRun = false;

  @override
  void didUpdateWidget(covariant _ActivityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificationOpenId == widget.notificationOpenId) return;
    _openedInitialRun = false;
    _openInitialApproval(context, context.read<ActivityCubit>().state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityCubit, ActivityState>(
      listener: _openInitialApproval,
      builder: (context, state) {
        return Column(
          children: [
            _FilterTabs(
              filter: filter,
              showProtocol: widget.isStandalone,
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
                  isStandalone: widget.isStandalone,
                ),
              },
            ),
          ],
        );
      },
    );
  }

  void _openInitialApproval(BuildContext context, ActivityState state) {
    if (_openedInitialRun || state.status != ActivityLoadStatus.ready) return;
    final run = _waitingRun(state.runs, widget.initialRunId);
    if (run == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openedInitialRun) return;
      _openedInitialRun = true;
      unawaited(TaskRunInteractionDialog.show(context, run));
    });
  }

  TaskRun? _waitingRun(List<TaskRun> runs, String? runId) {
    if (runId == null) return null;
    for (final run in runs) {
      if (run.id.value == runId &&
          run.status == TaskRunStatus.waitingForApproval) {
        return run;
      }
    }
    return null;
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.filter,
    required this.onChanged,
    required this.showProtocol,
  });

  final TaskActivityFilter filter;
  final ValueChanged<TaskActivityFilter> onChanged;

  /// Nur Standalone hat ein Protokoll, und lesen dürfen es nur Admins.
  final bool showProtocol;

  @override
  Widget build(BuildContext context) {
    if (!showProtocol) return _segments(includeProtocol: false);
    return BlocSelector<CurrentRuntimeUserCubit, CurrentRuntimeUserState, bool>(
      selector: (state) => state.isAdmin,
      builder: (context, isAdmin) => _segments(includeProtocol: isAdmin),
    );
  }

  Widget _segments({required bool includeProtocol}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: CupertinoSlidingSegmentedControl<TaskActivityFilter>(
        groupValue: filter,
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        children: {
          TaskActivityFilter.approvalRequired: Text('Interaktionen'),
          TaskActivityFilter.denied: Text('Abgelehnt'),
          TaskActivityFilter.running: Text('Laufend'),
          TaskActivityFilter.history: Text('Verlauf'),
          if (includeProtocol)
            TaskActivityFilter.protocol: const Text('Protokoll'),
        },
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.filter,
    required this.state,
    required this.isStandalone,
  });

  final TaskActivityFilter filter;
  final ActivityState state;
  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    return switch (filter) {
      TaskActivityFilter.approvalRequired => ApprovalRunGrid(
        runs: _approvalRequiredRuns,
        emptyText: 'Keine Aufgaben warten auf eine Eingabe oder Freigabe.',
      ),
      TaskActivityFilter.denied => TaskRunList(
        runs: _deniedRuns,
        emptyText: 'Keine abgelehnten Aufgaben.',
      ),
      TaskActivityFilter.running => TaskRunList(
        runs: _runningRuns,
        emptyText: 'Keine Aufgaben werden gerade ausgeführt.',
      ),
      TaskActivityFilter.history => TaskActivityHistory(
        activities: state.activities,
        onRefresh: context.read<ActivityCubit>().load,
      ),
      TaskActivityFilter.protocol when isStandalone =>
        const RuntimeApplicationLogsView(),
      TaskActivityFilter.protocol => const SizedBox.shrink(),
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
