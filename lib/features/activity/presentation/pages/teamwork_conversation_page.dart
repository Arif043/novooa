import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_activity.dart';
import '../widgets/activity_tab_content.dart';
import '../widgets/teamwork_conversation/teamwork_conversation_message.dart';

/// Das Gespräch zwischen Orchestrator, Mitarbeitern und Prüfung einer Teamarbeit, in zeitlicher Reihenfolge.
class TeamworkConversationPage extends StatelessWidget {
  const TeamworkConversationPage({super.key, required this.activity});

  final TaskActivity activity;

  @override
  Widget build(BuildContext context) {
    final entries = activity.conversation;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.ui_teamwork_conversation_title.tr()),
      ),
      body: entries.isEmpty
          ? ActivityEmptyState(
              text: LocaleKeys.ui_teamwork_conversation_empty.tr(),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, index) =>
                  TeamworkConversationMessage(entry: entries[index]),
            ),
    );
  }
}
