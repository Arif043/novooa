import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/model_catalog_entry.dart';
import '../cubits/model_catalog_cubit.dart';
import 'model_size_label.dart';

class ModelEntryTile extends StatelessWidget {
  const ModelEntryTile({
    super.key,
    required this.entry,
    required this.isSaving,
  });

  final ModelCatalogEntry entry;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final detail =
        '${entry.inputCount} Eingänge, ${entry.outputCount} Ausgänge, '
        '${modelSizeLabel(entry.sizeBytes)}';
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.memory_outlined),
      title: Text(entry.titleFor(languageTag)),
      subtitle: Text('${entry.descriptionFor(languageTag)}\n$detail'),
      isThreeLine: true,
      trailing: _RemoveButton(entry: entry, isSaving: isSaving),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.entry, required this.isSaving});

  final ModelCatalogEntry entry;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: entry.isCached ? 'Aus dem Cache entfernen' : 'Modell entfernen',
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
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    final title = entry.titleFor(languageTag);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          entry.isCached ? 'Aus dem Cache entfernen?' : 'Modell entfernen?',
        ),
        content: Text(
          entry.isCached
              ? '„$title“ wird aus dem Cache entfernt. Aufgaben, die das '
                    'Modell nutzen, laden es beim nächsten Lauf erneut herunter.'
              : '„$title“ wird aus der Runtime entfernt. Aufgaben, die das '
                    'Modell nutzen, können nicht mehr ausgeführt werden.',
        ),
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
