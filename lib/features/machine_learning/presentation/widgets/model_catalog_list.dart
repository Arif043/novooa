import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/model_catalog_entry.dart';
import '../cubits/model_catalog_cubit.dart';
import '../cubits/model_catalog_state.dart';
import 'model_entry_tile.dart';

/// Lokal vorliegende Modelle einer Herkunft (gecacht oder eigen) mit Lade-, Fehler- und Leerzustand.
class ModelCatalogList extends StatelessWidget {
  const ModelCatalogList({
    super.key,
    required this.state,
    required this.entries,
    required this.emptyText,
  });

  final ModelCatalogState state;
  final List<ModelCatalogEntry> entries;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ModelCatalogStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ModelCatalogStatus.failure => Center(
        child: OutlinedButton.icon(
          onPressed: context.read<ModelCatalogCubit>().load,
          icon: const Icon(Icons.refresh),
          label: const Text('Erneut versuchen'),
        ),
      ),
      ModelCatalogStatus.ready when entries.isEmpty => Text(
        emptyText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      ModelCatalogStatus.ready => Column(
        children: [
          for (final entry in entries) ...[
            ModelEntryTile(entry: entry, isSaving: state.isSaving),
            const Divider(),
          ],
        ],
      ),
    };
  }
}
