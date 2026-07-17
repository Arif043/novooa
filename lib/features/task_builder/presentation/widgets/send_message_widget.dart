import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class SendMessageWidget extends StatefulWidget {
  const SendMessageWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<SendMessageWidget> createState() => _SendMessageWidgetState();
}

class _SendMessageWidgetState extends State<SendMessageWidget> {
  late final TextEditingController _recipientController;
  late final TextEditingController _messageController;

  SendChannelMessageNodeConfig get _config {
    return widget.node.config as SendChannelMessageNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: _config.recipient);
    _messageController = TextEditingController(text: _config.message);
  }

  @override
  void didUpdateWidget(SendMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_recipientController, _config.recipient);
    _sync(_messageController, _config.message);
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _recipientController,
            decoration: InputDecoration(labelText: _recipientLabel),
            onChanged: _updateRecipient,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _messageController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Nachricht'),
            onChanged: _updateMessage,
          ),
        ],
      ),
    );
  }

  String get _title {
    return switch (_config.kind) {
      ChannelEventKind.email => 'E-Mail senden',
      ChannelEventKind.whatsapp => 'WhatsApp senden',
      ChannelEventKind.sms => 'SMS senden',
    };
  }

  String get _recipientLabel {
    return _config.kind == ChannelEventKind.email
        ? 'Empfänger'
        : 'Telefonnummer';
  }

  void _updateRecipient(String value) {
    context.read<TaskBuilderCubit>().updateSendMessageRecipient(
      widget.node.id,
      value,
    );
  }

  void _updateMessage(String value) {
    context.read<TaskBuilderCubit>().updateSendMessageBody(
      widget.node.id,
      value,
    );
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
