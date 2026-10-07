import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_search_tile.dart';

/// Trefferliste mit Lade-, Fehler- und Leerzustand des globalen Katalogs.
class ModelSearchResults extends StatelessWidget {
  const ModelSearchResults({
    super.key,
    required this.state,
    required this.models,
    required this.hasQuery,
  });

  final ModelCatalogState state;
  final List<ModelCatalogEntry> models;
  final bool hasQuery;

  bool get _catalogLoading =>
      state.globalStatus == ModelCatalogStatus.loading ||
      state.status == ModelCatalogStatus.loading;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty && _catalogLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.globalStatus == ModelCatalogStatus.failure)
          const _CatalogUnavailable(),
        Expanded(
          child: models.isEmpty
              ? _NoResults(hasQuery: hasQuery)
              : ListView.separated(
                  itemCount: models.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => ModelSearchTile(
                    model: models[index],
                    onTap: () => Navigator.of(context).pop(models[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CatalogUnavailable extends StatelessWidget {
  const _CatalogUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Der Modellkatalog ist gerade nicht erreichbar. Angezeigt '
                'werden nur Modelle, die diese Runtime bereits hat.',
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: context.read<ModelCatalogCubit>().loadGlobal,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Kein Modell gefunden', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasQuery
                  ? 'Versuche einen anderen Suchbegriff.'
                  : 'Für diesen Baustein steht noch kein passendes Modell '
                        'bereit. Eigene Modelle importierst du in den '
                        'Einstellungen unter Machine Learning.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
