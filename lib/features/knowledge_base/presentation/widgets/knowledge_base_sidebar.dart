import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';

class KnowledgeBaseSidebar extends StatelessWidget {
  const KnowledgeBaseSidebar({super.key, required this.state});

  final KnowledgeBaseState state;

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
            _SidebarHeader(count: state.notes.length),
            const SizedBox(height: AppSpacing.md),
            _SearchField(query: state.query),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _NoteList(state: state)),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Syscat Vault',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: 'Notiz erstellen',
          onPressed: context.read<KnowledgeBaseCubit>().createNote,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Notizen durchsuchen',
      ),
      onChanged: context.read<KnowledgeBaseCubit>().setQuery,
    );
  }
}

class _NoteList extends StatelessWidget {
  const _NoteList({required this.state});

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    final notes = state.visibleNotes;
    if (notes.isEmpty) return const Center(child: Text('Keine Treffer.'));
    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteTile(
          note: note,
          selected: note.id == state.selectedNote?.id,
        );
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.selected});

  final KnowledgeNote note;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      leading: Icon(_iconFor(note.type)),
      title: Text(note.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(note.path, overflow: TextOverflow.ellipsis),
      onTap: () => context.read<KnowledgeBaseCubit>().selectNote(note.id),
    );
  }
}

IconData _iconFor(KnowledgeNoteType type) {
  return switch (type) {
    KnowledgeNoteType.atomic => Icons.notes_outlined,
    KnowledgeNoteType.moc => Icons.account_tree_outlined,
    KnowledgeNoteType.unknown => Icons.article_outlined,
  };
}
