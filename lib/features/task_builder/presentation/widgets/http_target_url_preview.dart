import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Zeigt, wohin die Anfrage geht: Basis-URL der Verbindung plus Pfad. Die
/// Basis-URL ist gedämpft, der eigene Pfad hervorgehoben. Eine absolute URL
/// ersetzt die Basis wie in der Runtime.
class HttpTargetUrlPreview extends StatelessWidget {
  const HttpTargetUrlPreview({
    super.key,
    required this.baseUrl,
    required this.path,
  });

  final String baseUrl;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final absolute = _absoluteUrl.hasMatch(path.trim());
    final base = absolute ? '' : baseUrl;
    final suffix = absolute ? path.trim() : _suffix();
    return Semantics(
      label: '${LocaleKeys.ui_http_target_url.tr()}: $base$suffix',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          0,
        ),
        child: Text.rich(
          TextSpan(
            style: style,
            children: [
              TextSpan(text: base),
              TextSpan(
                text: suffix,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _absoluteUrl = RegExp(r'^https?://', caseSensitive: false);

  // Gleiche Zusammensetzung wie `connection-http-client.ts` in der Runtime.
  String _suffix() {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed.startsWith('/') || trimmed.startsWith('?')) {
      return trimmed;
    }
    return '/$trimmed';
  }
}
