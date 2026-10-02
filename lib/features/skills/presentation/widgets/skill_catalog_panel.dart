import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/skill_catalog.dart';
import '../cubits/skill_catalog_cubit.dart';
import '../cubits/skill_catalog_state.dart';
import '../cubits/skill_import_cubit.dart';

/// Suche im Katalog (skills.sh); ohne Eingabe die aktuell beliebtesten Skills.
class SkillCatalogPanel extends StatelessWidget {
  const SkillCatalogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkillCatalogCubit, SkillCatalogState>(
      builder: (context, state) => switch (state.status) {
        SkillCatalogStatus.checking => const Center(
          child: CircularProgressIndicator(),
        ),
        SkillCatalogStatus.unavailable => const _Unavailable(),
        _ => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Katalog durchsuchen',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: context.read<SkillCatalogCubit>().queryChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _Results(state: state)),
          ],
        ),
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final SkillCatalogState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SkillCatalogStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SkillCatalogStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message ?? 'Der Katalog ist nicht erreichbar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: context.read<SkillCatalogCubit>().retry,
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        );
      case SkillCatalogStatus.ready when state.items.isEmpty:
        return const Center(child: Text('Keine Skills gefunden.'));
      default:
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) =>
              _CatalogTile(skill: state.items[index]),
        );
    }
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.skill});

  final CatalogSkill skill;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(skill.name),
      subtitle: Text('${skill.source} · ${skill.installs} Installationen'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.read<SkillImportCubit>().startFromCatalog(skill.id),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Der Katalog ist nicht eingerichtet. Importiere Skills über GitHub, '
          'ZIP oder einen Ordner.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
