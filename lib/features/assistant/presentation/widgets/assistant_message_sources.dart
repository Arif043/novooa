import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/assistant_url_source.dart';

class AssistantMessageSources extends StatelessWidget {
  const AssistantMessageSources({super.key, required this.sources});

  final List<AssistantUrlSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quellen', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          for (final source in sources) _AssistantUrlSourceTile(source: source),
        ],
      ),
    );
  }
}

class _AssistantUrlSourceTile extends StatelessWidget {
  const _AssistantUrlSourceTile({required this.source});

  final AssistantUrlSource source;

  @override
  Widget build(BuildContext context) {
    final isRetrieved = source.status == AssistantUrlSourceStatus.retrieved;
    final color = isRetrieved
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Quelle ${source.url}',
      child: TextButton.icon(
        onPressed: isRetrieved ? () => _openSource(context) : null,
        icon: Icon(isRetrieved ? Icons.open_in_new : Icons.link_off),
        label: Text(_label),
        style: TextButton.styleFrom(foregroundColor: color),
      ),
    );
  }

  String get _label => '$_statusLabel: ${source.url.host}';

  String get _statusLabel => switch (source.status) {
    AssistantUrlSourceStatus.retrieved => 'Abgerufen',
    AssistantUrlSourceStatus.unavailable => 'Nicht abrufbar',
    AssistantUrlSourceStatus.paywalled => 'Bezahlschranke',
    AssistantUrlSourceStatus.unsafe => 'Nicht verfügbar',
  };

  Future<void> _openSource(BuildContext context) async {
    final opened = await launchUrl(
      source.url,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quelle konnte nicht geöffnet werden.')),
      );
    }
  }
}
