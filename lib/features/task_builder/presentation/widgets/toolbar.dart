import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';
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
            IconButton(
              tooltip: 'Nachricht senden hinzufügen',
              icon: const Icon(Icons.send_outlined),
              onPressed: () => _showSendMessageActions(context),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.humanApproval),
              icon: const Icon(Icons.face),
              tooltip: "Freigabe hinzufügen",
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.dialogInput),
              icon: const Icon(Icons.dynamic_form_outlined),
              tooltip: 'Formulareingabe hinzufügen',
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.mediaInput),
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'Bild-Eingabe hinzufügen',
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addNodeToMainGraph(.modelInference),
              icon: const Icon(Icons.model_training_outlined),
              tooltip: 'Modell-Inferenz hinzufügen',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSendMessageActions(BuildContext context) async {
    final kind = await showIosActionSheet<ChannelEventKind>(
      context: context,
      title: 'Nachricht senden',
      actions: const [
        IosAction(label: 'WhatsApp senden', value: ChannelEventKind.whatsapp),
        IosAction(label: 'SMS senden', value: ChannelEventKind.sms),
        IosAction(label: 'E-Mail senden', value: ChannelEventKind.email),
      ],
    );
    if (kind == null || !context.mounted) return;
    context.read<TaskBuilderCubit>().addSendMessageNodeToMainGraph(kind);
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
