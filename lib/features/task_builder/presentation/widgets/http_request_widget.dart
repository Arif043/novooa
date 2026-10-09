import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/runtime/connections_availability.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/connections/presentation/widgets/connection_picker_field.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_suggestion.dart';
import 'template_expression_text_field.dart';

/// Konfiguration der HTTP-Anfrage: Verbindung, Methode, Adresse, Parameter,
/// Header und Body. Zugangsdaten gibt es hier nicht — sie gehören zur
/// Verbindung und bleiben in der Runtime.
class HttpRequestWidget extends StatelessWidget {
  const HttpRequestWidget({super.key, required this.node});

  final WorkflowNode node;

  HttpRequestNodeConfig get _config => node.config as HttpRequestNodeConfig;

  @override
  Widget build(BuildContext context) {
    final connections = connectionsAvailable()
        ? context.watch<ConnectionsCubit>().state.connections
        : const <Connection>[];
    final suggestions = TemplateExpressionScope.suggestionsOf(context);
    final config = _config;
    final hasConnection = config.connectionId.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.ui_http_anfrage.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          ConnectionPickerField(
            selectedId: config.connectionId,
            connections: connections,
            noneLabel: LocaleKeys.ui_none_full_url.tr(),
            onChanged: (id) =>
                _update(context, (c) => c.copyWith(connectionId: id)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<HttpRequestMethod>(
                  key: ValueKey('${node.id.value}.method'),
                  isExpanded: true,
                  initialValue: config.method,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.ui_methode.tr(),
                  ),
                  items: [
                    for (final method in HttpRequestMethod.values)
                      DropdownMenuItem(value: method, child: Text(method.wire)),
                  ],
                  onChanged: (method) {
                    if (method != null) {
                      _update(context, (c) => c.copyWith(method: method));
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TemplateExpressionTextField(
                  value: config.url,
                  suggestions: suggestions,
                  decoration: InputDecoration(
                    labelText: hasConnection ? 'Pfad' : 'URL',
                    hintText: hasConnection
                        ? '/search/order'
                        : 'https://api.example.com/orders',
                    helperText: hasConnection
                        ? LocaleKeys.ui_relative_to_base_url.tr()
                        : LocaleKeys.ui_no_connection_no_auth.tr(),
                  ),
                  onChanged: (value) =>
                      _update(context, (c) => c.copyWith(url: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _NameValueList(
            title: LocaleKeys.ui_query_parameter.tr(),
            addLabel: LocaleKeys.ui_add_parameter.tr(),
            items: config.query,
            suggestions: suggestions,
            onChanged: (items) =>
                _update(context, (c) => c.copyWith(query: items)),
          ),
          const SizedBox(height: AppSpacing.md),
          _NameValueList(
            title: 'Header',
            addLabel: LocaleKeys.ui_add_header.tr(),
            items: config.headers,
            suggestions: suggestions,
            onChanged: (items) =>
                _update(context, (c) => c.copyWith(headers: items)),
          ),
          if (config.method.sendsBody) ...[
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<HttpBodyType>(
              segments: [
                ButtonSegment(
                  value: HttpBodyType.none,
                  label: Text(LocaleKeys.ui_kein_body.tr()),
                ),
                ButtonSegment(value: HttpBodyType.json, label: Text('JSON')),
                ButtonSegment(
                  value: HttpBodyType.text,
                  label: Text(LocaleKeys.ui_text.tr()),
                ),
              ],
              selected: {config.bodyType},
              onSelectionChanged: (selection) => _update(
                context,
                (c) => c.copyWith(bodyType: selection.first),
              ),
            ),
            if (config.bodyType != HttpBodyType.none) ...[
              const SizedBox(height: AppSpacing.sm),
              TemplateExpressionTextField(
                value: config.body,
                suggestions: suggestions,
                minLines: 3,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Body',
                  hintText: config.bodyType == HttpBodyType.json
                      ? '{"kunde": "{{kunde}}"}'
                      : null,
                ),
                onChanged: (value) =>
                    _update(context, (c) => c.copyWith(body: value)),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          // Eigenes Material, damit die Berührungseffekte der Kachel im
          // dekorierten Panel sichtbar bleiben.
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(LocaleKeys.ui_bei_fehlerstatus_abbrechen.tr()),
              subtitle: Text(LocaleKeys.ui_http_status_hint.tr()),
              value: config.failOnHttpError,
              onChanged: (value) =>
                  _update(context, (c) => c.copyWith(failOnHttpError: value)),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 200,
              child: TextFormField(
                key: ValueKey('${node.id.value}.timeout'),
                initialValue: '${config.timeoutSeconds}',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: LocaleKeys.ui_zeitlimit_sekunden.tr(),
                  helperText: LocaleKeys.ui_1_bis_120.tr(),
                ),
                onChanged: (text) {
                  final seconds = int.tryParse(text.trim());
                  if (seconds == null) return;
                  _update(
                    context,
                    (c) => c.copyWith(timeoutSeconds: seconds.clamp(1, 120)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    HttpRequestNodeConfig Function(HttpRequestNodeConfig config) update,
  ) {
    context.read<TaskBuilderCubit>().updateHttpRequest(node.id, update);
  }
}

class _NameValueList extends StatelessWidget {
  const _NameValueList({
    required this.title,
    required this.addLabel,
    required this.items,
    required this.suggestions,
    required this.onChanged,
  });

  final String title;
  final String addLabel;
  final List<HttpNameValue> items;
  final List<TemplateExpressionSuggestion> suggestions;
  final ValueChanged<List<HttpNameValue>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TemplateExpressionTextField(
                    value: items[index].name,
                    suggestions: suggestions,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.ui_name.tr(),
                    ),
                    onChanged: (name) =>
                        _replace(index, items[index].copyWith(name: name)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: TemplateExpressionTextField(
                    value: items[index].value,
                    suggestions: suggestions,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.ui_wert.tr(),
                    ),
                    onChanged: (value) =>
                        _replace(index, items[index].copyWith(value: value)),
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.ui_entfernen.tr(),
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged([
                    for (var other = 0; other < items.length; other++)
                      if (other != index) items[other],
                  ]),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(addLabel),
            onPressed: () => onChanged([...items, const HttpNameValue()]),
          ),
        ),
      ],
    );
  }

  void _replace(int index, HttpNameValue item) {
    onChanged([
      for (var other = 0; other < items.length; other++)
        if (other == index) item else items[other],
    ]);
  }
}
