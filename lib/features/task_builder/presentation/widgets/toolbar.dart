import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: .circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: SyscatTheme.glassSurface,
          borderRadius: .circular(999),
          border: Border.all(color: SyscatTheme.borderLight),
          boxShadow: SyscatTheme.glassShadows,
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.stringInput,
              feedback: const _DraggingDummy(icon: Icons.text_fields),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.stringInput),
                icon: const Icon(Icons.text_fields),
                tooltip: "Text bauen",
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.script,
              feedback: const _DraggingDummy(icon: Icons.terminal),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.script),
                icon: const Icon(Icons.code),
                tooltip: "Script hinzufügen",
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.prompt,
              feedback: const _DraggingDummy(icon: Icons.format_align_left),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.prompt),
                icon: const Icon(Icons.format_align_left),
                tooltip: "Prompt hinzufügen",
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Draggable<WorkflowPrimitive>(
              data: WorkflowPrimitive.conditional,
              feedback: const _DraggingDummy(icon: Icons.call_split),
              child: IconButton(
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .addNodeToMainGraph(.conditional),
                icon: const Icon(Icons.call_split),
                tooltip: "Verzweigung hinzufügen",
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.iterativeRefinement),
              icon: const Icon(Icons.auto_awesome),
              tooltip: "Verfeinerung hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.writeFile),
              icon: const Icon(Icons.note_add_outlined),
              tooltip: "Datei schreiben hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.readFile),
              icon: const Icon(Icons.file_open_outlined),
              tooltip: "Datei lesen hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addChannelEventNodeToMainGraph(ChannelEventKind.email),
              icon: const Icon(Icons.mark_email_read_outlined),
              tooltip: "E-Mail lesen hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addChannelEventNodeToMainGraph(ChannelEventKind.whatsapp),
              icon: const Icon(Icons.chat_outlined),
              tooltip: "WhatsApp lesen hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addChannelEventNodeToMainGraph(ChannelEventKind.sms),
              icon: const Icon(Icons.sms_outlined),
              tooltip: "SMS lesen hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            PopupMenuButton<ChannelEventKind>(
              tooltip: 'Nachricht senden hinzufügen',
              icon: const Icon(Icons.send_outlined),
              onSelected: (kind) => context
                  .read<TaskBuilderCubit>()
                  .addSendMessageNodeToMainGraph(kind),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ChannelEventKind.whatsapp,
                  child: Text('WhatsApp senden'),
                ),
                PopupMenuItem(
                  value: ChannelEventKind.sms,
                  child: Text('SMS senden'),
                ),
                PopupMenuItem(
                  value: ChannelEventKind.email,
                  child: Text('E-Mail senden'),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.humanApproval),
              icon: const Icon(Icons.face),
              tooltip: "Freigabe hinzufügen",
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggingDummy extends StatelessWidget {
  const _DraggingDummy({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 96,
        height: 64,
        decoration: SyscatTheme.nodePanelDecoration,
        child: Icon(icon, color: SyscatTheme.primaryOrange),
      ),
    );
  }
}
