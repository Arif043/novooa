import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';
import 'knowledge_markdown_preview.dart';

class KnowledgeBaseEditor extends StatefulWidget {
  const KnowledgeBaseEditor({super.key, required this.note});

  final KnowledgeNote note;

  @override
  State<KnowledgeBaseEditor> createState() => _KnowledgeBaseEditorState();
}

class _KnowledgeBaseEditorState extends State<KnowledgeBaseEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void didUpdateWidget(KnowledgeBaseEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id == widget.note.id) return;
    _syncController(_titleController, widget.note.title);
    _syncController(_contentController, widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SyscatTheme.glassPanelDecoration.copyWith(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EditorToolbar(note: widget.note),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.displayLarge,
              decoration: const InputDecoration(hintText: 'Titel'),
              onChanged: context.read<KnowledgeBaseCubit>().updateTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 620) return _EditorOnly(this);
                  return _SplitEditor(state: this);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({required this.note});

  final KnowledgeNote note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedButton<KnowledgeNoteType>(
          segments: const [
            ButtonSegment(
              value: KnowledgeNoteType.atomic,
              icon: Icon(Icons.notes_outlined),
              label: Text('Atomar'),
            ),
            ButtonSegment(
              value: KnowledgeNoteType.moc,
              icon: Icon(Icons.account_tree_outlined),
              label: Text('MOC'),
            ),
          ],
          selected: {
            note.type == KnowledgeNoteType.moc
                ? note.type
                : KnowledgeNoteType.atomic,
          },
          onSelectionChanged: (value) {
            context.read<KnowledgeBaseCubit>().updateType(value.first);
          },
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Notiz löschen',
          onPressed: context.read<KnowledgeBaseCubit>().deleteSelected,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _SplitEditor extends StatelessWidget {
  const _SplitEditor({required this.state});

  final _KnowledgeBaseEditorState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _MarkdownEditor(state)),
        const VerticalDivider(width: AppSpacing.lg),
        Expanded(
          child: KnowledgeMarkdownPreview(content: state.widget.note.content),
        ),
      ],
    );
  }
}

class _EditorOnly extends StatelessWidget {
  const _EditorOnly(this.state);

  final _KnowledgeBaseEditorState state;

  @override
  Widget build(BuildContext context) => _MarkdownEditor(state);
}

class _MarkdownEditor extends StatelessWidget {
  const _MarkdownEditor(this.state);

  final _KnowledgeBaseEditorState state;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: state._contentController,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontFamily: 'monospace', height: 1.45),
      decoration: const InputDecoration(
        hintText: 'Schreibe Markdown. Links: [[Andere Notiz]]',
      ),
      onChanged: context.read<KnowledgeBaseCubit>().updateContent,
    );
  }
}
