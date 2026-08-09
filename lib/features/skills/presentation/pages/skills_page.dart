import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_draft.dart';
import '../cubits/skills_cubit.dart';
import '../cubits/skills_state.dart';
import '../widgets/skill_editor_dialog.dart';

/// Übersichtsseite für Fähigkeiten (Skills). Zeigt eine Liste team-weiter
/// Skills mit Aktionen zum Erstellen, Bearbeiten und Löschen.
class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<SkillsCubit>()..load(),
      child: const _SkillsView(),
    );
  }
}

class _SkillsView extends StatelessWidget {
  const _SkillsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SkillsCubit, SkillsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onCreate: () => _createSkill(context)),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _Body(state: state)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createSkill(BuildContext context) async {
    final cubit = context.read<SkillsCubit>();
    final draft = await showIosDialog<SkillDraft>(
      context: context,
      builder: (_) => const SkillEditorDialog(),
    );
    if (draft == null) return;
    await cubit.createSkill(draft);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Fähigkeiten', style: SyscatTheme.taskBody)),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Fähigkeit anlegen'),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final SkillsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      SkillsStatus.loading => const Center(child: CircularProgressIndicator()),
      SkillsStatus.failure => _Failure(message: state.message),
      SkillsStatus.ready when state.skills.isEmpty => const _EmptyState(),
      SkillsStatus.ready => _SkillList(skills: state.skills),
    };
  }
}

class _SkillList extends StatelessWidget {
  const _SkillList({required this.skills});

  final List<Skill> skills;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: skills.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final skill = skills[index];
        return _SkillTile(skill: skill);
      },
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SyscatTheme.nodePanelDecoration,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.title, style: SyscatTheme.taskBody),
                if (skill.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    skill.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SyscatTheme.taskBodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Löschen',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<SkillsCubit>();
    final loaded = await cubit.loadContent(skill.id);
    if (!context.mounted || loaded == null) return;
    final draft = await showIosDialog<SkillDraft>(
      context: context,
      builder: (_) => SkillEditorDialog(initial: loaded),
    );
    if (draft == null) return;
    await cubit.updateSkill(skillId: skill.id, draft: draft);
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<SkillsCubit>();
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Fähigkeit löschen?'),
        content: Text('„${skill.title}" wird endgültig entfernt.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.deleteSkill(skill.id);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Lege deine erste Fähigkeit an, um sie an Bausteine anzuhängen.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? 'Fähigkeiten konnten nicht geladen werden.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => context.read<SkillsCubit>().load(),
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
