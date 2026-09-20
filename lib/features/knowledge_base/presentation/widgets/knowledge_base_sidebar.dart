import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';

class KnowledgeBaseSidebar extends StatelessWidget {
  const KnowledgeBaseSidebar({
    super.key,
    required this.state,
    this.onNoteOpened,
  });
  final VoidCallback? onNoteOpened;

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarHeader(
              count: state.notes.length,
              onNoteOpened: onNoteOpened,
            ),
            const SizedBox(height: AppSpacing.md),
            _SearchField(query: state.query),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _NoteList(state: state, onNoteOpened: onNoteOpened),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.count, this.onNoteOpened});
  final VoidCallback? onNoteOpened;

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Notizen · $count',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: 'Notiz erstellen',
          onPressed: () async {
            final cubit = context.read<KnowledgeBaseCubit>();
            await cubit.createNote();
            if (context.mounted &&
                cubit.state.status != KnowledgeBaseStatus.failure) {
              onNoteOpened?.call();
            }
          },
          icon: const Icon(CupertinoIcons.square_pencil),
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
    return TextFormField(
      initialValue: query,
      decoration: const InputDecoration(
        prefixIcon: Icon(CupertinoIcons.search),
        labelText: 'Notizen durchsuchen',
      ),
      onChanged: context.read<KnowledgeBaseCubit>().setQuery,
    );
  }
}

class _NoteList extends StatelessWidget {
  const _NoteList({required this.state, this.onNoteOpened});
  final VoidCallback? onNoteOpened;

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
          onNoteOpened: onNoteOpened,
        );
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.selected,
    this.onNoteOpened,
  });
  final VoidCallback? onNoteOpened;

  final KnowledgeNote note;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primary.withValues(alpha: .09) : colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        selected: selected,
        selectedColor: colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          note.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            note.content.trim().isEmpty
                ? 'Noch kein Inhalt'
                : note.content.replaceAll(RegExp(r'[#*\n]'), ' ').trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        onTap: () {
          context.read<KnowledgeBaseCubit>().selectNote(note.id);
          onNoteOpened?.call();
        },
      ),
    );
  }
}
