import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/localization/locale_keys.g.dart';
import '../../../domain/entities/teamwork_conversation_entry.dart';

/// Übersetzte Beschriftungen, Symbole und Farben eines Gesprächseintrags.
extension TeamworkConversationLabels on TeamworkConversationEntry {
  /// Wer zu wem spricht, etwa „Orchestrator → Elektriker“.
  String get direction {
    final orchestrator = LocaleKeys.ui_teamwork_conversation_orchestrator.tr();
    final member = memberName ?? '';
    final (from, to) = switch (kind) {
      TeamworkConversationKind.task => (orchestrator, member),
      TeamworkConversationKind.answer ||
      TeamworkConversationKind.failure => (member, orchestrator),
      TeamworkConversationKind.reviewPassed ||
      TeamworkConversationKind.reviewRejected => (
        LocaleKeys.ui_teamwork_conversation_review.tr(),
        orchestrator,
      ),
      TeamworkConversationKind.result => (orchestrator, null),
    };
    if (to == null) return from;
    return LocaleKeys.ui_teamwork_conversation_from_to.tr(
      namedArgs: {'from': from, 'to': to},
    );
  }

  String get kindLabel {
    final roundText = '${round ?? 1}';
    return switch (kind) {
      TeamworkConversationKind.task =>
        LocaleKeys.ui_teamwork_conversation_kind_task.tr(),
      TeamworkConversationKind.answer =>
        LocaleKeys.ui_teamwork_conversation_kind_answer.tr(),
      TeamworkConversationKind.failure =>
        LocaleKeys.ui_teamwork_conversation_kind_failure.tr(),
      TeamworkConversationKind.reviewPassed =>
        LocaleKeys.ui_teamwork_conversation_kind_review_passed.tr(
          namedArgs: {'round': roundText},
        ),
      TeamworkConversationKind.reviewRejected =>
        LocaleKeys.ui_teamwork_conversation_kind_review_rejected.tr(
          namedArgs: {'round': roundText},
        ),
      TeamworkConversationKind.result =>
        LocaleKeys.ui_teamwork_conversation_kind_result.tr(),
    };
  }

  IconData get icon => switch (kind) {
    TeamworkConversationKind.task => Icons.assignment_outlined,
    TeamworkConversationKind.answer => Icons.chat_bubble_outline,
    TeamworkConversationKind.failure => Icons.error_outline,
    TeamworkConversationKind.reviewPassed => Icons.verified_outlined,
    TeamworkConversationKind.reviewRejected => Icons.report_outlined,
    TeamworkConversationKind.result => Icons.flag_outlined,
  };

  /// Hintergrund und Schrift der Karte: Orchestrator, Mitarbeiter, Prüfung und Fehler unterscheiden sich.
  (Color, Color) colorsIn(ColorScheme colors) => switch (kind) {
    TeamworkConversationKind.task || TeamworkConversationKind.result => (
      colors.primaryContainer,
      colors.onPrimaryContainer,
    ),
    TeamworkConversationKind.answer => (
      colors.surfaceContainerHigh,
      colors.onSurface,
    ),
    TeamworkConversationKind.reviewPassed => (
      colors.tertiaryContainer,
      colors.onTertiaryContainer,
    ),
    TeamworkConversationKind.failure ||
    TeamworkConversationKind.reviewRejected => (
      colors.errorContainer,
      colors.onErrorContainer,
    ),
  };
}
