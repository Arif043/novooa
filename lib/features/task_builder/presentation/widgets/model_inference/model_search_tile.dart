import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/widgets/model_size_label.dart';
import '../../../../machine_learning/presentation/widgets/model_language_label.dart';
import '../../../../machine_learning/presentation/widgets/model_task_label.dart';
import '../../../../machine_learning/domain/entities/model_tag_vocabulary.dart';

class ModelSearchTile extends StatelessWidget {
  const ModelSearchTile({
    super.key,
    required this.model,
    this.vocabulary = ModelTagVocabulary.empty,
    required this.onTap,
  });

  final ModelCatalogEntry model;
  final ModelTagVocabulary vocabulary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    final details = [
      modelSizeLabel(model.sizeBytes),
      for (final tag in model.tags) vocabulary.labelFor(tag, languageTag),
    ].join(' · ');
    return ListTile(
      onTap: onTap,
      leading: Icon(model.task.icon),
      title: Text(model.titleFor(languageTag)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.descriptionFor(languageTag),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(text: model.task.label),
              for (final language in model.languages)
                _MetaChip(text: languageLabel(language)),
              if (model.origin case final origin?)
                _MetaChip(
                  text: origin == ModelOrigin.catalog
                      ? 'Gecacht'
                      : 'Eigenes Modell',
                  emphasized: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(details, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.text, this.emphasized = false});

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: emphasized
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
