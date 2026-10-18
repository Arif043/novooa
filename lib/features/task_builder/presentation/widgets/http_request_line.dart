import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/node_config.dart';
import 'field_helper_text.dart';
import 'http_target_url_preview.dart';
import 'template_expression_suggestion.dart';
import 'template_expression_text_field.dart';

/// Anfragezeile wie in API-Werkzeugen: Methode und Pfad nebeneinander,
/// darunter die vollständige Zieladresse aus Basis-URL und Pfad.
class HttpRequestLine extends StatelessWidget {
  const HttpRequestLine({
    super.key,
    required this.fieldKey,
    required this.method,
    required this.url,
    required this.hasConnection,
    required this.baseUrl,
    required this.suggestions,
    required this.onMethodChanged,
    required this.onUrlChanged,
  });

  final String fieldKey;
  final HttpRequestMethod method;
  final String url;

  final bool hasConnection;

  /// Basis-URL der gewählten Verbindung; `null`, solange sie unbekannt ist,
  /// etwa weil die Verbindung gelöscht wurde.
  final String? baseUrl;
  final List<TemplateExpressionSuggestion> suggestions;
  final ValueChanged<HttpRequestMethod> onMethodChanged;
  final ValueChanged<String> onUrlChanged;

  @override
  Widget build(BuildContext context) {
    final base = baseUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(flex: 2, child: _methodField()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 5, child: _urlField()),
          ],
        ),
        if (!hasConnection)
          FieldHelperText(LocaleKeys.ui_no_connection_no_auth.tr())
        else if (base == null)
          FieldHelperText(LocaleKeys.ui_relative_to_base_url.tr())
        else
          HttpTargetUrlPreview(baseUrl: base, path: url),
      ],
    );
  }

  Widget _methodField() {
    return DropdownButtonFormField<HttpRequestMethod>(
      key: ValueKey('$fieldKey.method'),
      isExpanded: true,
      initialValue: method,
      decoration: InputDecoration(labelText: LocaleKeys.ui_methode.tr()),
      items: [
        for (final method in HttpRequestMethod.values)
          DropdownMenuItem(value: method, child: Text(method.wire)),
      ],
      onChanged: (method) {
        if (method != null) onMethodChanged(method);
      },
    );
  }

  Widget _urlField() {
    return TemplateExpressionTextField(
      value: url,
      suggestions: suggestions,
      decoration: InputDecoration(
        labelText: hasConnection
            ? LocaleKeys.ui_http_path.tr()
            : LocaleKeys.ui_http_url.tr(),
        hintText: hasConnection
            ? '/search/order'
            : 'https://api.example.com/orders',
      ),
      onChanged: onUrlChanged,
    );
  }
}
