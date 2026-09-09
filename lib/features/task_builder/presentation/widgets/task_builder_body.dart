import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/scroll_boundary_fade.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';

class TaskBuilderBody extends StatefulWidget {
  const TaskBuilderBody({super.key, required this.state});

  final TaskBuilderState state;

  @override
  State<TaskBuilderBody> createState() => _TaskBuilderBodyState();
}

class _TaskBuilderBodyState extends State<TaskBuilderBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        const Toolbar(),
        const SizedBox(height: AppSpacing.xl),
        if (widget.state case TaskBuilderLoaded(:final editingTask))
          Expanded(
            child: ScrollBoundaryFade(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xxl,
                    right: AppSpacing.xxl,
                    bottom: AppSpacing.xxl,
                  ),
                  child: NodeGraph(nodes: editingTask.nodes),
                ),
              ),
            ),
          ),
        // SizedBox(height: AppSpacing.xxl)
      ],
    );
  }
}
