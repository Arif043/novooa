import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';

class KnowledgeBaseEditor extends StatefulWidget {
  const KnowledgeBaseEditor({
    super.key,
    required this.note,
    required this.titleActions,
  });

  final KnowledgeNote note;
  final Widget titleActions;

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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Titel',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onChanged: context.read<KnowledgeBaseCubit>().updateTitle,
          ),
          widget.titleActions,
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _MarkdownEditor(this)),
        ],
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
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      decoration: const InputDecoration(
        labelText: 'Notizinhalt',
        alignLabelWithHint: true,
        hintText: 'Halte dein Wissen fest. Verlinke mit [[Andere Notiz]].',
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
      onChanged: context.read<KnowledgeBaseCubit>().updateContent,
    );
  }
}
