import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

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
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<KnowledgeBaseMainMode>(
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
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: _content()),
      ],
    );
  }

  Widget _content() {
    return switch (_mode) {
      KnowledgeBaseMainMode.editor => KnowledgeBaseEditor(
        note: widget.state.selectedNote!,
      ),
      KnowledgeBaseMainMode.preview => KnowledgeMarkdownPreview(
        content: widget.state.selectedNote!.content,
      ),
      KnowledgeBaseMainMode.graph => KnowledgeBaseGraphView(
        notes: widget.state.notes,
        selectedNoteId: widget.state.selectedNote?.id,
      ),
    };
  }
}
