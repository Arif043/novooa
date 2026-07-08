import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';

class TaskTitleField extends StatefulWidget {
  const TaskTitleField({super.key});

  @override
  State<TaskTitleField> createState() => _TaskTitleFieldState();
}

class _TaskTitleFieldState extends State<TaskTitleField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncTitle(context, context.watch<TaskBuilderCubit>().state);
    return BlocListener<TaskBuilderCubit, TaskBuilderState>(
      listener: _syncTitle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Name der Aufgabe',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleLarge,
          textInputAction: TextInputAction.done,
          onChanged: context.read<TaskBuilderCubit>().updateTitle,
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
