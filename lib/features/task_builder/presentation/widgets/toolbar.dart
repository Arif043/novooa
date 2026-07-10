import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: .circular(999),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: .circular(999),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.stringInput,
              feedback: StringInputNodeDraggingDummy(),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.stringInput),
                icon: const Icon(Icons.text_fields),
                tooltip: "Texteingabe hinzufügen",
              ),
            ),
            const SizedBox(width: 4),
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.script,
              feedback: ScriptNodeDraggingDummy(),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.script),
                icon: const Icon(Icons.terminal),
                tooltip: "Script hinzufügen",
              ),
            ),
            const SizedBox(width: 4),
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.prompt,
              feedback: PromptNodeDraggingDummy(),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.prompt),
                icon: const Icon(Icons.format_align_left),
                tooltip: "Prompt hinzufügen",
              ),
            ),
            const SizedBox(width: 4),
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.conditional,
              feedback: ConditionalNodeDraggingDummy(),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.conditional),
                icon: const Icon(Icons.call_split),
                tooltip: "Verzweigung hinzufügen",
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.iterativeRefinement),
              icon: const Icon(Icons.auto_awesome),
              tooltip: "Verfeinerung hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.writeFile),
              icon: const Icon(Icons.note_add_outlined),
              tooltip: "Datei schreiben hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.humanApproval),
              icon: const Icon(Icons.face),
              tooltip: "Freigabe hinzufügen",
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => {},
              icon: const Icon(Icons.code),
              tooltip: "Menschliche Aktion hinzufügen",
            ),
          ],
        ),
      ),
    );
  }
}

class StringInputNodeDraggingDummy extends StatelessWidget {
  const StringInputNodeDraggingDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(child: Icon(Icons.text_fields)),
    );
  }
}

class PromptNodeDraggingDummy extends StatelessWidget {
  const PromptNodeDraggingDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(child: Icon(Icons.format_align_left)),
    );
  }
}

class ScriptNodeDraggingDummy extends StatelessWidget {
  const ScriptNodeDraggingDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(child: Icon(Icons.terminal)),
    );
  }
}

class ConditionalNodeDraggingDummy extends StatelessWidget {
  const ConditionalNodeDraggingDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Center(child: Icon(Icons.call_split)),
    );
  }
}
