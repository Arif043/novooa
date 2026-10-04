import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/model_catalog_entry.dart';
import '../cubits/model_catalog_cubit.dart';
import '../cubits/model_catalog_state.dart';

class GlobalModelCatalogList extends StatelessWidget {
  const GlobalModelCatalogList({super.key, required this.state});

  final ModelCatalogState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.globalStatus) {
      ModelCatalogStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ModelCatalogStatus.failure => _CatalogLoadFailure(),
      ModelCatalogStatus.ready when state.globalEntries.isEmpty => const Text(
        'Der globale Katalog enthält noch keine Modelle.',
      ),
      ModelCatalogStatus.ready => Column(
        children: [
          for (final entry in state.globalEntries) ...[
            _GlobalModelTile(
              entry: entry,
              isSaving: state.isSaving,
              isInstalled: state.entries.any((item) => item.id == entry.id),
            ),
            const Divider(),
          ],
        ],
      ),
    };
  }
}

class _CatalogLoadFailure extends StatelessWidget {
  const _CatalogLoadFailure();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text('Der globale Modellkatalog konnte nicht geladen werden.'),
      ),
      const SizedBox(width: AppSpacing.md),
      OutlinedButton.icon(
        onPressed: context.read<ModelCatalogCubit>().loadGlobal,
        icon: const Icon(Icons.refresh),
        label: const Text('Erneut versuchen'),
      ),
    ],
  );
}

class _GlobalModelTile extends StatelessWidget {
  const _GlobalModelTile({
    required this.entry,
    required this.isSaving,
    required this.isInstalled,
  });

  final ModelCatalogEntry entry;
  final bool isSaving;
  final bool isInstalled;

  @override
  Widget build(BuildContext context) {
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isInstalled
            ? Icons.download_done_outlined
            : Icons.cloud_download_outlined,
      ),
      title: Text(entry.titleFor(languageTag)),
      subtitle: Text(entry.descriptionFor(languageTag)),
      trailing: IconButton(
        tooltip: isInstalled
            ? 'Modell ist installiert'
            : 'Modell herunterladen',
        onPressed: isSaving || isInstalled
            ? null
            : () => context.read<ModelCatalogCubit>().installGlobalModel(
                entry.id,
              ),
        icon: Icon(isInstalled ? Icons.check : Icons.download_outlined),
      ),
    );
  }
}
