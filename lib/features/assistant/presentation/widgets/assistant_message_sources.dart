import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
          Text(
            LocaleKeys.ui_quellen.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
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
      label: LocaleKeys.ui_source_url.tr(
        namedArgs: {'url': source.url.toString()},
      ),
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
    AssistantUrlSourceStatus.unsafe => LocaleKeys.ui_not_available.tr(),
  };

  Future<void> _openSource(BuildContext context) async {
    final opened = await launchUrl(
      source.url,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleKeys.ui_quelle_konnte_nicht_geoeffnet_werden.tr(),
          ),
        ),
      );
    }
  }
}
