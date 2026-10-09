import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

class SendMessageWidget extends StatefulWidget {
  const SendMessageWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<SendMessageWidget> createState() => _SendMessageWidgetState();
}

class _SendMessageWidgetState extends State<SendMessageWidget> {
  SendChannelMessageNodeConfig get _config {
    return widget.node.config as SendChannelMessageNodeConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.recipient,
            cursorTarget: TaskBuilderCursorTargets.field(
              widget.node.id,
              NodeFieldKey.recipient,
            ),
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: InputDecoration(labelText: _recipientLabel),
            onChanged: _updateRecipient,
          ),
          if (_config.kind == ChannelEventKind.email) ...[
            const SizedBox(height: AppSpacing.sm),
            TemplateExpressionTextField(
              value: _config.subject,
              suggestions: TemplateExpressionScope.suggestionsOf(context),
              decoration: InputDecoration(
                labelText: LocaleKeys.ui_betreff.tr(),
              ),
              onChanged: _updateSubject,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.message,
            cursorTarget: TaskBuilderCursorTargets.field(
              widget.node.id,
              NodeFieldKey.message,
            ),
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_nachricht.tr(),
            ),
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
        ? LocaleKeys.ui_recipient.tr()
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

  void _updateSubject(String value) {
    context.read<TaskBuilderCubit>().updateSendMessageSubject(
      widget.node.id,
      value,
    );
  }
}
