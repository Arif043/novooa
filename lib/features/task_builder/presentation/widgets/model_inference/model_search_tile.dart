import 'package:flutter/material.dart';

import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/widgets/model_size_label.dart';

class ModelSearchTile extends StatelessWidget {
  const ModelSearchTile({super.key, required this.model, required this.onTap});

  final ModelCatalogEntry model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    final tags = model.tagsFor(languageTag);
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.memory_outlined),
      title: Text(model.titleFor(languageTag)),
      subtitle: Text(
        [
          model.descriptionFor(languageTag),
          [
            modelSizeLabel(model.sizeBytes),
            if (tags.isNotEmpty) tags.join(' · '),
          ].join(' · '),
        ].join('\n'),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: _OriginBadge(model: model),
    );
  }
}

class _OriginBadge extends StatelessWidget {
  const _OriginBadge({required this.model});

  final ModelCatalogEntry model;

  @override
  Widget build(BuildContext context) {
    final label = switch (model.origin) {
      ModelOrigin.catalog => 'Gecacht',
      ModelOrigin.import => 'Eigenes Modell',
      null => null,
    };
    if (label == null) return const SizedBox.shrink();
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}
