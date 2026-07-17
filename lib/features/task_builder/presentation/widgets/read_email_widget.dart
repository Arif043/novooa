import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

class ReadEventWidget extends StatelessWidget {
  const ReadEventWidget({super.key, required this.node});

  final WorkflowNode node;

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
          Text(_outputs),
        ],
      ),
    );
  }

  String get _title {
    final config = node.config;
    if (config is! ReadChannelEventNodeConfig) return 'E-Mail lesen';
    return switch (config.kind) {
      ChannelEventKind.email => 'E-Mail lesen',
      ChannelEventKind.whatsapp => 'WhatsApp lesen',
      ChannelEventKind.sms => 'SMS lesen',
    };
  }

  String get _outputs {
    final config = node.config;
    if (config is! ReadChannelEventNodeConfig ||
        config.kind == ChannelEventKind.email) {
      return 'Ausgaben: Absender, Betreff, Nachricht, Ankunftszeit';
    }
    return 'Ausgaben: Absender, Nachricht, Ankunftszeit';
  }
}
