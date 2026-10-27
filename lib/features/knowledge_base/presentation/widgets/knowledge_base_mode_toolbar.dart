import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

enum KnowledgeBaseMainMode { editor, preview, graph }

/// Ansichten der Notiz als Symbolknöpfe links, Löschen rechts. Symbole statt Beschriftung
/// passen auch in schmale Fenster; die Bezeichnung steht im Tooltip und für Screenreader.
class KnowledgeBaseModeToolbar extends StatelessWidget {
  const KnowledgeBaseModeToolbar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onDelete,
  });

  final KnowledgeBaseMainMode mode;
  final ValueChanged<KnowledgeBaseMainMode> onModeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          container: true,
          label: LocaleKeys.ui_knowledge_views.tr(),
          child: Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final option in KnowledgeBaseMainMode.values)
                _ModeButton(
                  mode: option,
                  selected: option == mode,
                  onPressed: () => onModeChanged(option),
                ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: LocaleKeys.ui_knowledge_note_delete.tr(),
          onPressed: onDelete,
          icon: const Icon(CupertinoIcons.trash, size: AppSpacing.gutter),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  final KnowledgeBaseMainMode mode;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: IconButton(
        tooltip: _label,
        isSelected: selected,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: selected ? colors.primary : colors.onSurfaceVariant,
          backgroundColor: selected ? colors.surfaceContainerHighest : null,
        ),
        icon: Icon(_icon, size: AppSpacing.gutter),
      ),
    );
  }

  String get _label => switch (mode) {
    KnowledgeBaseMainMode.editor => LocaleKeys.ui_knowledge_mode_write.tr(),
    KnowledgeBaseMainMode.preview => LocaleKeys.ui_knowledge_mode_read.tr(),
    KnowledgeBaseMainMode.graph => LocaleKeys.ui_knowledge_mode_graph.tr(),
  };

  IconData get _icon => switch (mode) {
    KnowledgeBaseMainMode.editor => CupertinoIcons.pencil,
    KnowledgeBaseMainMode.preview => CupertinoIcons.book,
    KnowledgeBaseMainMode.graph => CupertinoIcons.share,
  };
}
