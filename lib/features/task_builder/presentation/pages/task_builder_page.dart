import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/widgets/root_shell_scope.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_employee_assignments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/write_file_folders_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_knowledge_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_language_models_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';
import 'package:syscat2/features/script_packages/presentation/cubits/script_packages_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_save_notice_listener.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_body.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_title_field.dart';

class TaskBuilderPage extends StatelessWidget {
  final Task? editingTaskOrNull;

  const TaskBuilderPage({super.key, this.editingTaskOrNull});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              serviceLocator<TaskBuilderCubit>()..load(editingTaskOrNull),
        ),
        BlocProvider(
          create: (_) => serviceLocator<NodeFileAttachmentsCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<WriteFileFoldersCubit>()..load(),
        ),
        BlocProvider(
          create: (_) =>
              serviceLocator<NodeKnowledgeAttachmentsCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<NodeLanguageModelsCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<ModelCatalogCubit>()
            ..load()
            ..loadGlobal(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<ScriptPackagesCubit>()..load(),
        ),
        BlocProvider(create: (_) => serviceLocator<ConnectionsCubit>()..load()),
        BlocProvider(
          create: (_) => serviceLocator<GoogleAccountsCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<NodeSkillAttachmentsCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<NodeEmployeeAssignmentsCubit>()..load(),
        ),
      ],
      child: _TaskBuilderShellTitle(
        child: Builder(
          builder: (context) => TaskSaveNoticeListener(
            notices: context.read<TaskBuilderCubit>().saveNotices,
            child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
              builder: (context, state) => TaskBuilderBody(state: state),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskBuilderShellTitle extends StatefulWidget {
  const _TaskBuilderShellTitle({required this.child});

  final Widget child;

  @override
  State<_TaskBuilderShellTitle> createState() => _TaskBuilderShellTitleState();
}

class _TaskBuilderShellTitleState extends State<_TaskBuilderShellTitle> {
  RootShellController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = RootShellScope.of(context);
    if (_controller == controller) return;
    _controller = controller;
    final cubit = context.read<TaskBuilderCubit>();
    _setTitleAfterFrame(
      controller,
      BlocProvider.value(value: cubit, child: const TaskTitleField()),
    );
  }

  void _setTitleAfterFrame(RootShellController controller, Widget title) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller != controller) return;
      controller.setTaskBuilderController(context.read<TaskBuilderCubit>());
      controller.setTitle(title);
    });
  }

  @override
  void dispose() {
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller?.setTitle(null);
      controller?.setTaskBuilderController(null);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
