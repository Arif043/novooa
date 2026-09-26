import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      ModelCatalogStatus.failure => OutlinedButton.icon(
        onPressed: context.read<ModelCatalogCubit>().loadGlobal,
        icon: const Icon(Icons.refresh),
        label: const Text('Erneut versuchen'),
      ),
      ModelCatalogStatus.ready when state.globalEntries.isEmpty => const Text(
        'Der globale Katalog enthält noch keine Modelle.',
      ),
      ModelCatalogStatus.ready => Column(
        children: [
          for (final entry in state.globalEntries) ...[
            _GlobalModelTile(entry: entry, isSaving: state.isSaving),
            const Divider(),
          ],
        ],
      ),
    };
  }
}

class _GlobalModelTile extends StatelessWidget {
  const _GlobalModelTile({required this.entry, required this.isSaving});

  final ModelCatalogEntry entry;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cloud_download_outlined),
      title: Text(entry.title),
      subtitle: Text(entry.description),
      trailing: IconButton(
        tooltip: 'Modell herunterladen',
        onPressed: isSaving
            ? null
            : () => context.read<ModelCatalogCubit>().installGlobalModel(
                entry.id,
              ),
        icon: const Icon(Icons.download_outlined),
      ),
    );
  }
}
