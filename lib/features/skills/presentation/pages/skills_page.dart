import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../cubits/skills_cubit.dart';
import '../cubits/skills_state.dart';
import '../widgets/skill_import_sheet.dart';
import '../widgets/skill_list_tile.dart';
import '../widgets/skills_folder_hint.dart';

/// Übersicht der Fähigkeiten (Skills). Der Skills-Ordner des Nutzers ist die
/// Quelle der Wahrheit: Die Seite zeigt, was darin liegt, und bietet den Import
/// (GitHub, ZIP, Ordner, Katalog) an.
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
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message!)));
        context.read<SkillsCubit>().messageShown();
      },
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onImport: () => SkillImportSheet.show(context)),
            const SizedBox(height: AppSpacing.md),
            SkillsFolderHint(
              location: state.location,
              onRescan: context.read<SkillsCubit>().load,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _Body(state: state)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Fähigkeiten', style: SyscatTheme.taskBody)),
        FilledButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Importieren'),
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
      SkillsStatus.ready => ListView.separated(
        itemCount: state.skills.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) =>
            SkillListTile(skill: state.skills[index]),
      ),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Noch keine Fähigkeiten. Importiere welche von GitHub, aus einem '
            'ZIP oder dem Katalog – oder lege einen Skill-Ordner mit einer '
            'SKILL.md in den Skills-Ordner.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: () => SkillImportSheet.show(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Skills importieren'),
          ),
        ],
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
            onPressed: context.read<SkillsCubit>().load,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
