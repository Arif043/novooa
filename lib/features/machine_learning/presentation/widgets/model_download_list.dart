import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/model_cache_status.dart';
import '../cubits/model_catalog_cubit.dart';
import '../cubits/model_catalog_state.dart';

/// Downloads, die die Runtime gerade ausführt oder die gescheitert sind.
class ModelDownloadList extends StatelessWidget {
  const ModelDownloadList({super.key, required this.state});

  final ModelCatalogState state;

  @override
  Widget build(BuildContext context) {
    final statuses = state.cacheStatuses.values
        .where((status) => state.localEntry(status.modelId) == null)
        .toList(growable: false);
    return Column(
      children: [
        for (final status in statuses) ...[
          _DownloadTile(status: status, title: _titleOf(context, status)),
          const Divider(),
        ],
      ],
    );
  }

  String _titleOf(BuildContext context, ModelCacheStatus status) {
    final languageTag = Localizations.localeOf(context).toLanguageTag();
    return state.entryById(status.modelId)?.titleFor(languageTag) ??
        status.modelId;
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.status, required this.title});

  final ModelCacheStatus status;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: status.isDownloading
          ? const Padding(
              padding: EdgeInsets.all(2),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.error_outline, color: colors.error),
      title: Text(title),
      subtitle: Text(
        status.isDownloading
            ? 'Wird heruntergeladen …'
            : status.message ?? 'Download fehlgeschlagen.',
      ),
      trailing: status.isDownloading
          ? null
          : TextButton(
              onPressed: () =>
                  context.read<ModelCatalogCubit>().cacheModel(status.modelId),
              child: const Text('Erneut versuchen'),
            ),
    );
  }
}
