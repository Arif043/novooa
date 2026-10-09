import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_anchor.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';

class TaskTitleField extends StatefulWidget {
  const TaskTitleField({super.key});

  @override
  State<TaskTitleField> createState() => _TaskTitleFieldState();
}

class _TaskTitleFieldState extends State<TaskTitleField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTitle(context, context.watch<TaskBuilderCubit>().state);
    return BlocListener<TaskBuilderCubit, TaskBuilderState>(
      listener: _syncTitle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: AgentCursorAnchor(
          target: TaskBuilderCursorTargets.taskTitle,
          onActivate: _focusNode.requestFocus,
          child: TextField(
            focusNode: _focusNode,
            controller: _controller,
            decoration: InputDecoration(
              hintText: LocaleKeys.task_builder_title_field_hint.tr(),
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(),
              suffixIcon: Icon(Icons.edit_outlined, size: 16),
            ),
            style: MediaQuery.sizeOf(context).width < 600
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.titleLarge,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            textInputAction: TextInputAction.done,
            onChanged: context.read<TaskBuilderCubit>().updateTitle,
          ),
        ),
      ),
    );
  }

  void _syncTitle(BuildContext context, TaskBuilderState state) {
    if (state case TaskBuilderLoaded(:final editingTask)) {
      _syncController(editingTask.title);
    }
  }

  void _syncController(String title) {
    if (_controller.text == title) return;
    _controller.value = _controller.value.copyWith(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }
}
