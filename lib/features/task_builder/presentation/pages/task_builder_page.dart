import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/logging/syscat_log.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_placeholder.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';

class TaskBuilderPage extends StatelessWidget {
  final Task? editingTaskOrNull;

  const TaskBuilderPage({super.key, this.editingTaskOrNull});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<TaskBuilderCubit>()..load(editingTaskOrNull),
      child: const _TaskBuilderView(),
    );
  }
}

class _TaskBuilderView extends StatelessWidget {
  const _TaskBuilderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
      builder: (context, state) => _TaskBuilderBody(state: state),
    );
  }
}

class _TaskBuilderBody extends StatefulWidget {
  const _TaskBuilderBody({required this.state});

  final TaskBuilderState state;

  @override
  State<_TaskBuilderBody> createState() => _TaskBuilderBodyState();
}

class _TaskBuilderBodyState extends State<_TaskBuilderBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return Column(
      children: [
        CupertinoButton.filled(
          onPressed: () async {
            final task = cubit.loadedTaskOrNull();
            if (task == null) return;
            logSyscatInfo(
              'Run-Button startet Aufgabe: ${task.id}',
              name: 'syscat.task_builder',
            );
            final taskExecutionOrFailure = await serviceLocator<ExecuteTask>()(
              ExecuteTaskParams(task: task),
            );
            taskExecutionOrFailure.when(
              (_) => logSyscatInfo(
                'Run-Button: Aufgabe erfolgreich ausgeführt.',
                name: 'syscat.task_builder',
              ),
              (failure) => logSyscatInfo(
                'Run-Button: Aufgabe fehlgeschlagen: ${failure.message}',
                name: 'syscat.task_builder',
              ),
            );
          },
          child: Text('Run Task'),
        ),
        Toolbar(),
        const SizedBox(height: AppSpacing.xxl),
        if (widget.state case TaskBuilderLoaded(:final editingTask))
          Expanded(
            child: WebSmoothScroll(
              controller: _scrollController,
              scrollSpeed: 2.5,
              scrollAnimationLength: 1400,
              curve: Curves.easeInOutCubic,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: NeverScrollableScrollPhysics(),
                child: NodeGraph(nodes: editingTask.nodes),
              ),
            ),
          ),
        NodePlaceholder(
          onAccept: (value) =>
              context.read<TaskBuilderCubit>().addNodeToMainGraph(value),
        ),
      ],
    );
  }
}
