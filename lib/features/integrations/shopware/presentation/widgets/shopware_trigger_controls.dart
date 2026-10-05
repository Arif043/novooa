import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/connections/presentation/widgets/connection_picker_field.dart';

import '../../domain/shopware_trigger_params.dart';

/// Einstellungen eines Shopware-Auslösers im Dialog „Auslöser hinzufügen“:
/// Verbindung, Ereignis und was zum Ereignis gehört. Braucht einen
/// [ConnectionsCubit] in der Umgebung.
class ShopwareTriggerControls extends StatelessWidget {
  const ShopwareTriggerControls({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ShopwareTriggerParams value;
  final ValueChanged<ShopwareTriggerParams> onChanged;

  @override
  Widget build(BuildContext context) {
    final connections = context.watch<ConnectionsCubit>().state.connections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConnectionPickerField(
          selectedId: value.connectionId,
          connections: connections,
          helperText: connections.isEmpty
              ? 'Lege unter Einstellungen → Verbindungen mit der Vorlage '
                    '„Shopware“ eine Verbindung an.'
              : 'Über sie lädt novooa die Daten zum Ereignis nach.',
          onChanged: (id) => onChanged(value.copyWith(connectionId: id)),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ShopwareTriggerEvent>(
          key: const Key('shopware-trigger-event'),
          isExpanded: true,
          initialValue: value.event,
          decoration: InputDecoration(
            labelText: 'Wann soll es starten?',
            helperText: value.event.description,
            helperMaxLines: 2,
          ),
          items: [
            for (final event in ShopwareTriggerEvent.values)
              DropdownMenuItem(value: event, child: Text(event.label)),
          ],
          onChanged: (event) {
            if (event != null) onChanged(value.copyWith(event: event));
          },
        ),
        ..._details(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Shopware meldet das Ereignis über eine kleine App, die du nach dem '
          'Erstellen auf der Karte des Auslösers findest.',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<Widget> _details() {
    switch (value.event) {
      case ShopwareTriggerEvent.orderStatus:
        return [
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<ShopwareStateScope>(
            key: const Key('shopware-trigger-scope'),
            isExpanded: true,
            initialValue: value.scope,
            decoration: const InputDecoration(labelText: 'Status von'),
            items: [
              for (final scope in ShopwareStateScope.values)
                DropdownMenuItem(value: scope, child: Text(scope.label)),
            ],
            onChanged: (scope) {
              if (scope != null) onChanged(value.copyWith(scope: scope));
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            key: ValueKey('shopware-trigger-state-${value.scope.name}'),
            isExpanded: true,
            initialValue: value.state,
            decoration: const InputDecoration(labelText: 'Zielstatus'),
            items: [
              for (final option in value.scope.states)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: (state) {
              if (state != null) onChanged(value.copyWith(state: state));
            },
          ),
        ];
      case ShopwareTriggerEvent.stockLow:
        return [
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('shopware-trigger-threshold'),
            initialValue: '${value.threshold}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bestand höchstens',
              helperText:
                  'Gemeldet wird bei jeder Änderung des Bestands, solange er '
                  'diese Grenze nicht überschreitet.',
              helperMaxLines: 3,
            ),
            onChanged: (text) {
              final number = int.tryParse(text.trim());
              if (number != null) {
                onChanged(value.copyWith(threshold: number));
              }
            },
          ),
        ];
      case ShopwareTriggerEvent.newsletterSubscribed:
        return [
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: const Key('shopware-trigger-confirmed'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Erst nach Bestätigung'),
            subtitle: const Text(
              'Aus: sofort bei der Anmeldung, auch ohne Bestätigung per E-Mail.',
            ),
            value: value.confirmedOnly,
            onChanged: (on) => onChanged(value.copyWith(confirmedOnly: on)),
          ),
        ];
      case ShopwareTriggerEvent.orderPlaced:
      case ShopwareTriggerEvent.customerRegistered:
        return const [];
    }
  }
}
