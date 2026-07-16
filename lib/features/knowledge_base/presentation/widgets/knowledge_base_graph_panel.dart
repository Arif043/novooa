import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/knowledge_note.dart';
import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';

class KnowledgeBaseGraphPanel extends StatelessWidget {
  const KnowledgeBaseGraphPanel({super.key, required this.state});

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
            _SaveIndicator(isSaving: state.isSaving),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _DetailsPanel(state: state)),
          ],
        ),
      ),
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.isSaving});

  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final icon = isSaving ? Icons.sync : Icons.check_circle_outline;
    final text = isSaving ? 'Speichert' : 'Gespeichert';
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.labelSmall),
        ),
      ],
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.state});

  final KnowledgeBaseState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Metadata(note: state.selectedNote!),
        const Divider(height: AppSpacing.xl),
        Expanded(
          child: ListView(
            children: [
              _LinkSection(title: 'Verlinkt', notes: state.linkedNotes),
              const SizedBox(height: AppSpacing.lg),
              _LinkSection(title: 'Backlinks', notes: state.backlinks),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.note});

  final KnowledgeNote note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eigenschaften', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _MetaRow(label: 'Pfad', value: note.path),
        _MetaRow(label: 'Typ', value: note.type.label),
        _MetaRow(label: 'Links', value: '${note.outgoingLinks.length}'),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.title, required this.notes});

  final String title;
  final List<KnowledgeNote> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (notes.isEmpty)
          Text('Keine Einträge.', style: Theme.of(context).textTheme.bodySmall)
        else
          for (final note in notes) _LinkedNoteTile(note: note),
      ],
    );
  }
}

class _LinkedNoteTile extends StatelessWidget {
  const _LinkedNoteTile({required this.note});

  final KnowledgeNote note;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(note.title, overflow: TextOverflow.ellipsis),
      onTap: () => context.read<KnowledgeBaseCubit>().selectNote(note.id),
    );
  }
}
