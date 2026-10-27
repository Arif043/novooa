import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/knowledge_base_state.dart';

enum KnowledgeSaveStatus {
  saving,
  saved,
  failed;

  static KnowledgeSaveStatus of(KnowledgeBaseState state) {
    if (state.isSaving) return KnowledgeSaveStatus.saving;
    if (state.status == KnowledgeBaseStatus.failure) {
      return KnowledgeSaveStatus.failed;
    }
    return KnowledgeSaveStatus.saved;
  }
}

/// Kleiner Speicherstatus neben den Ansichtsknöpfen — ersetzt die Snackbar nach jedem
/// automatischen Speichern. Screenreader hören Änderungen über die Live-Region.
class KnowledgeSaveStatusLabel extends StatelessWidget {
  const KnowledgeSaveStatusLabel({super.key, required this.status});

  final KnowledgeSaveStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status == KnowledgeSaveStatus.failed
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(_icon, size: AppSpacing.md, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (status) {
    KnowledgeSaveStatus.saving => CupertinoIcons.arrow_2_circlepath,
    KnowledgeSaveStatus.saved => CupertinoIcons.checkmark_alt_circle,
    KnowledgeSaveStatus.failed => CupertinoIcons.exclamationmark_circle,
  };

  String get _label => switch (status) {
    KnowledgeSaveStatus.saving => LocaleKeys.ui_knowledge_saving.tr(),
    KnowledgeSaveStatus.saved => LocaleKeys.ui_knowledge_saved.tr(),
    KnowledgeSaveStatus.failed => LocaleKeys.ui_knowledge_save_failed.tr(),
  };
}
