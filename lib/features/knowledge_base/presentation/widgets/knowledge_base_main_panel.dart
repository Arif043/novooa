import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';
import 'knowledge_base_editor.dart';
import 'knowledge_base_graph_view.dart';
import 'knowledge_base_mode_toolbar.dart';
import 'knowledge_markdown_preview.dart';

class KnowledgeBaseMainPanel extends StatefulWidget {
  const KnowledgeBaseMainPanel({super.key, required this.state});
  final KnowledgeBaseState state;
  @override
  State<KnowledgeBaseMainPanel> createState() => _KnowledgeBaseMainPanelState();
}

class _KnowledgeBaseMainPanelState extends State<KnowledgeBaseMainPanel> {
  KnowledgeBaseMainMode _mode = KnowledgeBaseMainMode.editor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final panel = Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: KnowledgeBaseModeToolbar(
              mode: _mode,
              onModeChanged: (value) => setState(() => _mode = value),
              onDelete: _delete,
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Expanded(child: _content()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.state.status == KnowledgeBaseStatus.failure
                    ? 'Speicherstatus prüfen'
                    : widget.state.isSaving
                    ? 'Wird gespeichert …'
                    : 'Automatisch gespeichert',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 440) {
          return SingleChildScrollView(
            child: SizedBox(height: 600, child: panel),
          );
        }
        return panel;
      },
    );
  }

  Widget _content() => switch (_mode) {
    KnowledgeBaseMainMode.editor => KnowledgeBaseEditor(
      note: widget.state.selectedNote!,
      titleActions: const SizedBox.shrink(),
    ),
    KnowledgeBaseMainMode.preview => Padding(
      padding: const EdgeInsets.all(24),
      child: KnowledgeMarkdownPreview(
        content: widget.state.selectedNote!.content,
        notes: widget.state.notes,
        onNoteSelected: context.read<KnowledgeBaseCubit>().selectNote,
      ),
    ),
    KnowledgeBaseMainMode.graph => KnowledgeBaseGraphView(
      notes: widget.state.notes,
      selectedNoteId: widget.state.selectedNote?.id,
    ),
  };

  Future<void> _delete() async {
    final cubit = context.read<KnowledgeBaseCubit>();
    final id = widget.state.selectedNote?.id;
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Notiz löschen?'),
        content: Text(
          '„${widget.state.selectedNote?.title}“ wird aus der Wissensbasis entfernt.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted && cubit.state.selectedNote?.id == id) {
      await cubit.deleteSelected();
    }
  }
}
