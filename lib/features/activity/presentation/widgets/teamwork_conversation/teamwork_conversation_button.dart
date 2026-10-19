import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_keys.g.dart';
import '../../../domain/entities/task_activity.dart';
import '../../pages/teamwork_conversation_page.dart';

/// Öffnet das Gespräch der Mitarbeiter einer Teamarbeit auf einer eigenen Seite.
class TeamworkConversationButton extends StatelessWidget {
  const TeamworkConversationButton({super.key, required this.activity});

  final TaskActivity activity;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.forum_outlined),
      label: Text(LocaleKeys.ui_teamwork_conversation_show.tr()),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeamworkConversationPage(activity: activity),
      ),
    );
  }
}
