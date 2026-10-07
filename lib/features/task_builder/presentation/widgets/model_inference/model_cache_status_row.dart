import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_cache_status.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';

/// „Wird geladen …“, „Gecacht“ oder Fehler mit „Erneut versuchen“ für das gewählte Modell.
class ModelCacheStatusRow extends StatelessWidget {
  const ModelCacheStatusRow({
    super.key,
    required this.modelId,
    required this.state,
  });

  final String modelId;
  final ModelCatalogState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final local = state.localEntry(modelId);
    final status = state.cacheStatuses[modelId];
    if (local != null) {
      return _StatusText(
        icon: Icon(Icons.check_circle_outline, color: colors.primary),
        text: local.origin == ModelOrigin.import
            ? 'Eigenes Modell'
            : 'Gecacht und bereit',
      );
    }
    if (status?.state == ModelCacheState.downloading) {
      return const _StatusText(
        icon: SizedBox.square(
          dimension: AppSpacing.md,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        text: 'Wird geladen …',
      );
    }
    return _StatusText(
      icon: Icon(
        status == null ? Icons.cloud_download_outlined : Icons.error_outline,
        color: status == null ? colors.onSurfaceVariant : colors.error,
      ),
      text: status == null
          ? 'Noch nicht gecacht – wird spätestens beim ersten Lauf geladen.'
          : status.message ?? 'Download fehlgeschlagen.',
      action: TextButton(
        onPressed: () => context.read<ModelCatalogCubit>().cacheModel(modelId),
        child: Text(status == null ? 'Jetzt laden' : 'Erneut versuchen'),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.icon, required this.text, this.action});

  final Widget icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          IconTheme.merge(
            data: const IconThemeData(size: AppSpacing.md),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
