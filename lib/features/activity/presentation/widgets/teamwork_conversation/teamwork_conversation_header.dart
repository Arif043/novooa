import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_keys.g.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/teamwork_conversation_entry.dart';
import 'teamwork_conversation_labels.dart';

/// Kopf eines Gesprächseintrags: Symbol, wer zu wem spricht, Art, Uhrzeit und Dauer.
class TeamworkConversationHeader extends StatelessWidget {
  const TeamworkConversationHeader({
    super.key,
    required this.entry,
    required this.foreground,
  });

  final TeamworkConversationEntry entry;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(entry.icon, color: foreground, semanticLabel: entry.kindLabel),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.direction,
                style: textTheme.titleSmall?.copyWith(color: foreground),
              ),
              Text(
                _details,
                style: textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _details {
    final local = entry.occurredAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    final duration = entry.duration;
    return [
      entry.kindLabel,
      time,
      if (duration != null)
        LocaleKeys.ui_teamwork_conversation_duration.tr(
          namedArgs: {
            'seconds': (duration.inMilliseconds / 1000).toStringAsFixed(1),
          },
        ),
    ].join(' · ');
  }
}
