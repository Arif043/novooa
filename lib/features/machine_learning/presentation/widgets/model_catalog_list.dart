import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/model_catalog_entry.dart';
import '../cubits/model_catalog_cubit.dart';
import '../cubits/model_catalog_state.dart';

class ModelCatalogList extends StatelessWidget {
  const ModelCatalogList({super.key, required this.state});

  final ModelCatalogState state;

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
      ModelCatalogStatus.ready when state.entries.isEmpty => const Text(
        'Noch keine ONNX-Modelle importiert.',
      ),
      ModelCatalogStatus.ready => Column(
        children: [
          for (final entry in state.entries) ...[
            _ModelEntryTile(entry: entry, isSaving: state.isSaving),
            const Divider(),
          ],
        ],
      ),
    };
  }
}

class _ModelEntryTile extends StatelessWidget {
  const _ModelEntryTile({required this.entry, required this.isSaving});

  final ModelCatalogEntry entry;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final detail =
        '${entry.inputCount} Eingänge, ${entry.outputCount} Ausgänge, ${_sizeLabel(entry.sizeBytes)}';
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.memory_outlined),
      title: Text(entry.titleFor(languageTag)),
      subtitle: Text('${entry.descriptionFor(languageTag)}\n$detail'),
      isThreeLine: true,
      trailing: entry.isManagedLocally
          ? _DeleteButton(entry: entry, isSaving: isSaving)
          : const Tooltip(
              message: 'Systemmodell',
              child: Icon(Icons.lock_outline),
            ),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.entry, required this.isSaving});

  final ModelCatalogEntry entry;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aus Katalog entfernen',
      onPressed: isSaving ? null : () => _remove(context),
      icon: const Icon(Icons.delete_outline),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final confirmed = await _confirm(context);
    if (confirmed != true || !context.mounted) return;
    await context.read<ModelCatalogCubit>().removeModel(entry.id);
  }

  Future<bool?> _confirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modell entfernen?'),
        content: Text('${entry.title} wird aus dem lokalen Katalog entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
