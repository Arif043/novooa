import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/skill_catalog.dart';
import '../../domain/entities/skill_import.dart';
import '../cubits/skill_import_cubit.dart';
import '../cubits/skill_import_state.dart';

/// Vorschau der gefundenen Skills: Auswahl, Hinweise und — bei Katalog-Skills —
/// die Sicherheitsprüfungen. Imports sind fremde Anweisungen; deshalb wird
/// nichts ohne diese Bestätigung gespeichert.
class SkillImportReview extends StatelessWidget {
  const SkillImportReview({super.key, required this.state});

  final SkillImportState state;

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();
    final cubit = context.read<SkillImportCubit>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        if (state.audits.isNotEmpty) _Audits(audits: state.audits),
        Row(
          children: [
            TextButton(
              onPressed: cubit.restart,
              child: const Text('Andere Quelle'),
            ),
            const Spacer(),
            if (preview.candidates.length > 1)
              TextButton(
                onPressed: () => cubit.selectAll(
                  state.selected.length != preview.candidates.length,
                ),
                child: Text(
                  state.selected.length == preview.candidates.length
                      ? 'Keine auswählen'
                      : 'Alle auswählen',
                ),
              ),
          ],
        ),
        for (final candidate in preview.candidates)
          _CandidateTile(
            candidate: candidate,
            selected: state.selected.contains(candidate.name),
            onToggle: () => cubit.toggle(candidate.name),
          ),
        for (final rejection in preview.rejected)
          _RejectedTile(rejection: rejection),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Skills sind Anweisungen von Dritten. Prüfe, ob du der Quelle '
          'vertraust. Enthaltene Skripte werden nie ausgeführt.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.onToggle,
  });

  final SkillImportCandidate candidate;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final notes = [
      if (candidate.nameTaken)
        'Der Name ist vergeben; es wird eine Nummer angehängt.',
      ...candidate.warnings,
    ];
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(candidate.name),
      subtitle: Text(
        [
          candidate.description,
          '${candidate.fileCount} Dateien',
          ...notes,
        ].join('\n'),
      ),
      isThreeLine: true,
    );
  }
}

class _RejectedTile extends StatelessWidget {
  const _RejectedTile({required this.rejection});

  final SkillImportRejection rejection;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
      title: Text(rejection.directory),
      subtitle: Text(rejection.reason),
    );
  }
}

class _Audits extends StatelessWidget {
  const _Audits({required this.audits});

  final List<CatalogAudit> audits;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [for (final audit in audits) _AuditChip(audit: audit)],
      ),
    );
  }
}

class _AuditChip extends StatelessWidget {
  const _AuditChip({required this.audit});

  final CatalogAudit audit;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (audit.status) {
      CatalogAuditStatus.pass => (Icons.verified_outlined, 'bestanden'),
      CatalogAuditStatus.warn => (Icons.warning_amber_rounded, 'Warnung'),
      CatalogAuditStatus.fail => (Icons.gpp_bad_outlined, 'durchgefallen'),
    };
    return Tooltip(
      message: audit.summary,
      child: Chip(
        avatar: Icon(icon, size: AppSpacing.md),
        label: Text('${audit.provider}: $label'),
      ),
    );
  }
}
