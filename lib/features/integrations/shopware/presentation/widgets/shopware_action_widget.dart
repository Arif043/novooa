import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/runtime/connections_availability.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/connections/presentation/widgets/connection_picker_field.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

import '../../domain/shopware_action_spec.dart';
import '../../domain/shopware_actions.dart';
import '../../domain/shopware_node_config.dart';

/// Formular einer Shopware-Aktion, gerendert aus ihrer [ShopwareActionSpec]:
/// Verbindung zum Shop und die Felder der Aktion.
class ShopwareActionWidget extends StatelessWidget {
  const ShopwareActionWidget({super.key, required this.node});

  final WorkflowNode node;

  ShopwareNodeConfig get _config => node.config as ShopwareNodeConfig;

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final spec = ShopwareActions.byId(config.action);
    // Eine unbekannte Aktion braucht keine Verbindungen und damit keinen Cubit.
    final needsConnection = spec != null && spec.usesConnection;
    final connections = needsConnection && connectionsAvailable()
        ? context.watch<ConnectionsCubit>().state.connections
        : const <Connection>[];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec?.title ?? 'Shopware', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          if (spec == null)
            Text(
              'Die Aktion „${config.action}“ kennt diese Version von novooa '
              'nicht.',
            )
          else ...[
            if (!spec.usesConnection)
              const Text(
                'Liefert Bestellung, Kunde, Produkt oder Anmeldung des '
                'Auslösers „Shopware-Ereignis“. Der Baustein funktioniert nur '
                'in Aufgaben mit diesem Auslöser.',
              )
            else
              ConnectionPickerField(
                selectedId: config.connectionId,
                connections: connections,
                helperText: connections.isEmpty
                    ? 'Lege unter Einstellungen → Verbindungen mit der Vorlage '
                          '„Shopware“ eine Verbindung an.'
                    : null,
                onChanged: (id) =>
                    _update(context, (c) => c.copyWith(connectionId: id)),
              ),
            for (final field in spec.fields) ...[
              const SizedBox(height: AppSpacing.sm),
              _FieldInput(
                nodeId: node.id,
                field: field,
                value: config.params[field.key],
                onChanged: (value) =>
                    _update(context, (c) => c.withParam(field.key, value)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    ShopwareNodeConfig Function(ShopwareNodeConfig config) update,
  ) {
    context.read<TaskBuilderCubit>().updatePluginNode(node.id, (config) {
      return config is ShopwareNodeConfig ? update(config) : config;
    });
  }
}

class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.nodeId,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final NodeId nodeId;
  final ShopwareField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (field.kind) {
      ShopwareFieldKind.text => TemplateExpressionTextField(
        value: value is String ? value as String : '',
        suggestions: TemplateExpressionScope.suggestionsOf(context),
        minLines: field.lines,
        maxLines: field.lines > 1 ? field.lines + 6 : 1,
        helperText: field.helper,
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
        ),
        onChanged: onChanged,
      ),
      ShopwareFieldKind.select => DropdownButtonFormField<String>(
        key: ValueKey('${nodeId.value}.${field.key}'),
        isExpanded: true,
        initialValue: _selected(),
        decoration: InputDecoration(
          labelText: field.label,
          helperText: field.helper,
        ),
        items: [
          for (final option in field.options)
            DropdownMenuItem(value: option.value, child: Text(option.label)),
        ],
        onChanged: (selection) {
          if (selection != null) onChanged(selection);
        },
      ),
      ShopwareFieldKind.number => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 200,
          child: TextFormField(
            key: ValueKey('${nodeId.value}.${field.key}'),
            initialValue: value == null ? '' : '$value',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: field.label,
              helperText: field.helper,
            ),
            onChanged: (text) {
              if (text.trim().isEmpty) return onChanged(null);
              final number = int.tryParse(text.trim());
              if (number == null) return;
              onChanged(number.clamp(field.min, field.max));
            },
          ),
        ),
      ),
      // Eigenes Material, damit die Berührungseffekte der Kachel im dekorierten
      // Panel sichtbar bleiben.
      ShopwareFieldKind.toggle => Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          key: ValueKey('${nodeId.value}.${field.key}'),
          contentPadding: EdgeInsets.zero,
          title: Text(field.label),
          subtitle: field.helper == null ? null : Text(field.helper!),
          value: value == true,
          onChanged: (on) => onChanged(on ? true : null),
        ),
      ),
    };
  }

  /// Ein gespeicherter Wert, den die Auswahl nicht kennt, fällt auf die erste
  /// Option zurück, statt das Formular abstürzen zu lassen.
  String _selected() {
    final stored = value is String ? value as String : '';
    final known = field.options.any((option) => option.value == stored);
    return known ? stored : field.options.first.value;
  }
}
