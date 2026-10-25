import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../features/runs/domain/repositories/run_repository.dart';
import '../features/runs/domain/usecases/review_run.dart';
import '../features/runs/domain/usecases/watch_runs.dart';
import '../features/runs/presentation/cubits/runs_cubit.dart';
import '../features/tasks/domain/entities/dashboard_task.dart';
import '../features/tasks/domain/repositories/task_catalog.dart';
import '../features/tasks/domain/usecases/start_task.dart';
import '../features/tasks/domain/usecases/watch_dashboard_tasks.dart';
import '../features/tasks/presentation/cubits/task_start_cubit.dart';
import '../features/tasks/presentation/cubits/tasks_cubit.dart';
import 'dashboard_config.dart';
import 'dashboard_dependencies.dart';
import 'dashboard_navigation.dart';

/// Stellt die Cubits der Features bereit und zeigt die Navigation.
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.dependencies});

  final DashboardDependencies dependencies;

  bool _isOffered(TaskId id) => DashboardConfig.showsTask(id.value);

  @override
  Widget build(BuildContext context) {
    final catalog = dependencies<TaskCatalog>();
    final runs = dependencies<RunRepository>();
    return RepositoryProvider(
      create: (_) => ReviewRun(runs),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                TasksCubit(WatchDashboardTasks(catalog, isOffered: _isOffered))
                  ..load(),
          ),
          BlocProvider(create: (_) => TaskStartCubit(StartTask(catalog))),
          BlocProvider(
            create: (_) => RunsCubit(
              WatchRuns(
                runs,
                isOffered: _isOffered,
                limit: DashboardConfig.visibleRunCount,
              ),
            )..load(),
          ),
        ],
        child: DashboardNavigation(
          onSignOut: context.read<RuntimeConnectionCubit>().signOut,
        ),
      ),
    );
  }
}
