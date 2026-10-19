import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_keys.g.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/teamwork_conversation_entry.dart';
import 'teamwork_conversation_header.dart';
import 'teamwork_conversation_labels.dart';

/// Ein Eintrag im Gespräch als Karte; Aufträge zeigen zusätzlich erwartetes Ergebnis und Grenzen.
class TeamworkConversationMessage extends StatelessWidget {
  const TeamworkConversationMessage({super.key, required this.entry});

  final TeamworkConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = entry.colorsIn(
      Theme.of(context).colorScheme,
    );
    return Card(
      margin: EdgeInsets.zero,
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TeamworkConversationHeader(entry: entry, foreground: foreground),
            const SizedBox(height: AppSpacing.sm),
            _MessageText(text: _body, color: foreground),
            if (entry.expectedResult case final expected?)
              _MessageSection(
                label: LocaleKeys.ui_teamwork_conversation_expected_result.tr(),
                text: expected,
                color: foreground,
              ),
            if (entry.boundaries case final boundaries?)
              _MessageSection(
                label: LocaleKeys.ui_teamwork_conversation_boundaries.tr(),
                text: boundaries,
                color: foreground,
              ),
          ],
        ),
      ),
    );
  }

  String get _body {
    if (entry.text.trim().isNotEmpty) return entry.text;
    return LocaleKeys.ui_teamwork_conversation_no_findings.tr();
  }
}

class _MessageSection extends StatelessWidget {
  const _MessageSection({
    required this.label,
    required this.text,
    required this.color,
  });

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelLarge?.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xs),
          _MessageText(text: text, color: color),
        ],
      ),
    );
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: color);
    return SelectableText(text, style: style);
  }
}
