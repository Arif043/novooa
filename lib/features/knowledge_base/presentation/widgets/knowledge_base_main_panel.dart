import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

import '../cubits/knowledge_base_state.dart';
import 'knowledge_base_editor.dart';
import 'knowledge_base_graph_view.dart';
import 'knowledge_markdown_preview.dart';

enum KnowledgeBaseMainMode { editor, preview, graph }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Expanded(child: _content())],
    );
  }

  Widget _content() {
    return switch (_mode) {
      KnowledgeBaseMainMode.editor => KnowledgeBaseEditor(
        note: widget.state.selectedNote!,
        titleActions: _NoteActions(mode: _mode, onModeChanged: _setMode),
      ),
      KnowledgeBaseMainMode.preview => _NonEditorPanel(
        actions: _NoteActions(mode: _mode, onModeChanged: _setMode),
        child: KnowledgeMarkdownPreview(
          content: widget.state.selectedNote!.content,
          notes: widget.state.notes,
          onNoteSelected: context.read<KnowledgeBaseCubit>().selectNote,
        ),
      ),
      KnowledgeBaseMainMode.graph => _NonEditorPanel(
        actions: _NoteActions(mode: _mode, onModeChanged: _setMode),
        child: KnowledgeBaseGraphView(
          notes: widget.state.notes,
          selectedNoteId: widget.state.selectedNote?.id,
        ),
      ),
    };
  }

  void _setMode(KnowledgeBaseMainMode mode) {
    setState(() => _mode = mode);
  }
}

class _NonEditorPanel extends StatelessWidget {
  const _NonEditorPanel({required this.actions, required this.child});

  final Widget actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: actions,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: child),
      ],
    );
  }
}

class _NoteActions extends StatelessWidget {
  const _NoteActions({required this.mode, required this.onModeChanged});

  final KnowledgeBaseMainMode mode;
  final ValueChanged<KnowledgeBaseMainMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<KnowledgeBaseMainMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: KnowledgeBaseMainMode.editor,
              icon: Icon(Icons.edit_note),
              label: Text('Editor'),
            ),
            ButtonSegment(
              value: KnowledgeBaseMainMode.preview,
              icon: Icon(Icons.visibility_outlined),
              label: Text('Ansicht'),
            ),
            ButtonSegment(
              value: KnowledgeBaseMainMode.graph,
              icon: Icon(Icons.hub_outlined),
              label: Text('Graph'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => onModeChanged(value.first),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Notiz löschen',
          onPressed: context.read<KnowledgeBaseCubit>().deleteSelected,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
