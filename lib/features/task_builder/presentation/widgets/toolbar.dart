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
    final actions = _actions(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
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
              for (final action in actions) ...[
                _ToolbarActionButton(action: action),
                if (action != actions.last)
                  const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_ToolbarAction> _actions(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return [
      _ToolbarAction(
        primitive: .stringInput,
        icon: Icons.text_fields,
        tooltip: 'Text bauen',
        onPressed: () => cubit.addNodeToMainGraph(.stringInput),
      ),
      _ToolbarAction(
        primitive: .script,
        icon: Icons.code,
        tooltip: 'Script hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.script),
      ),
      _ToolbarAction(
        primitive: .prompt,
        icon: Icons.format_align_left,
        tooltip: 'Prompt hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.prompt),
      ),
      _ToolbarAction(
        primitive: .conditional,
        icon: Icons.call_split,
        tooltip: 'Verzweigung hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.conditional),
      ),
      _ToolbarAction(
        primitive: .iterativeRefinement,
        icon: Icons.auto_awesome,
        tooltip: 'Verfeinerung hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.iterativeRefinement),
      ),
      _ToolbarAction(
        primitive: .writeFile,
        icon: Icons.note_add_outlined,
        tooltip: 'Datei schreiben hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.writeFile),
      ),
      _ToolbarAction(
        primitive: .readFile,
        icon: Icons.file_open_outlined,
        tooltip: 'Datei lesen hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.readFile),
      ),
      _ToolbarAction(
        primitive: .readChannelEvent,
        icon: Icons.mark_email_read_outlined,
        tooltip: 'E-Mail lesen hinzufügen',
        onPressed: () =>
            cubit.addChannelEventNodeToMainGraph(ChannelEventKind.email),
      ),
      _ToolbarAction(
        primitive: .readChannelEvent,
        icon: Icons.chat_outlined,
        tooltip: 'WhatsApp lesen hinzufügen',
        onPressed: () =>
            cubit.addChannelEventNodeToMainGraph(ChannelEventKind.whatsapp),
      ),
      _ToolbarAction(
        primitive: .readChannelEvent,
        icon: Icons.sms_outlined,
        tooltip: 'SMS lesen hinzufügen',
        onPressed: () =>
            cubit.addChannelEventNodeToMainGraph(ChannelEventKind.sms),
      ),
      _ToolbarAction(
        primitive: .sendChannelMessage,
        icon: Icons.send_outlined,
        tooltip: 'Nachricht senden hinzufügen',
        onPressed: () => _showSendMessageActions(context),
      ),
      _ToolbarAction(
        primitive: .humanApproval,
        icon: Icons.face,
        tooltip: 'Freigabe hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.humanApproval),
      ),
      _ToolbarAction(
        primitive: .dialogInput,
        icon: Icons.dynamic_form_outlined,
        tooltip: 'Formulareingabe hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.dialogInput),
      ),
      _ToolbarAction(
        primitive: .mediaInput,
        icon: Icons.add_a_photo_outlined,
        tooltip: 'Bild-Eingabe hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.mediaInput),
      ),
      _ToolbarAction(
        primitive: .modelInference,
        icon: Icons.model_training_outlined,
        tooltip: 'Modell-Inferenz hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.modelInference),
      ),
      _ToolbarAction(
        primitive: .textToSpeech,
        icon: Icons.volume_up_outlined,
        tooltip: 'Text vorlesen hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.textToSpeech),
      ),
      _ToolbarAction(
        primitive: .speechToText,
        icon: Icons.graphic_eq_outlined,
        tooltip: 'Audio transkribieren hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.speechToText),
      ),
      _ToolbarAction(
        primitive: .forEach,
        icon: Icons.repeat_outlined,
        tooltip: 'Für jedes Element hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.forEach),
      ),
      _ToolbarAction(
        primitive: .documentLookup,
        icon: Icons.manage_search_outlined,
        tooltip: 'Datensatz suchen hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.documentLookup),
      ),
      _ToolbarAction(
        primitive: .saveDocument,
        icon: Icons.save_outlined,
        tooltip: 'Datensatz speichern hinzufügen',
        onPressed: () => cubit.addNodeToMainGraph(.saveDocument),
      ),
    ];
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

class _ToolbarAction {
  const _ToolbarAction({
    required this.primitive,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final WorkflowPrimitive primitive;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

class _ToolbarActionButton extends StatelessWidget {
  const _ToolbarActionButton({required this.action});

  final _ToolbarAction action;

  @override
  Widget build(BuildContext context) {
    return Draggable<WorkflowPrimitive>(
      data: action.primitive,
      feedback: _DraggingDummy(icon: action.icon),
      child: IconButton(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        tooltip: action.tooltip,
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
        decoration: SyscatTheme.nodePanelDecoration(context),
        child: Icon(icon, color: SyscatTheme.primaryOrange),
      ),
    );
  }
}
