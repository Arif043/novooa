import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
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
              ? LocaleKeys.shopware_ui_create_connection_hint.tr()
              : LocaleKeys.shopware_ui_trigger_connection_helper.tr(),
          onChanged: (id) => onChanged(value.copyWith(connectionId: id)),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ShopwareTriggerEvent>(
          key: const Key('shopware-trigger-event'),
          isExpanded: true,
          initialValue: value.event,
          decoration: InputDecoration(
            labelText: LocaleKeys.shopware_ui_trigger_when.tr(),
            helperText: value.event.descriptionKey.tr(),
            helperMaxLines: 2,
          ),
          items: [
            for (final event in ShopwareTriggerEvent.values)
              DropdownMenuItem(value: event, child: Text(event.labelKey.tr())),
          ],
          onChanged: (event) {
            if (event != null) onChanged(value.copyWith(event: event));
          },
        ),
        ..._details(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          LocaleKeys.shopware_ui_trigger_app_hint.tr(),
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
            decoration: InputDecoration(
              labelText: LocaleKeys.shopware_ui_trigger_scope.tr(),
            ),
            items: [
              for (final scope in ShopwareStateScope.values)
                DropdownMenuItem(
                  value: scope,
                  child: Text(scope.labelKey.tr()),
                ),
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
            decoration: InputDecoration(
              labelText: LocaleKeys.shopware_ui_trigger_state.tr(),
            ),
            items: [
              for (final option in value.scope.states)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.labelKey.tr()),
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
            decoration: InputDecoration(
              labelText: LocaleKeys.shopware_ui_trigger_threshold.tr(),
              helperText: LocaleKeys.shopware_ui_trigger_threshold_helper.tr(),
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
            title: Text(LocaleKeys.shopware_ui_trigger_confirmed_only.tr()),
            subtitle: Text(
              LocaleKeys.shopware_ui_trigger_confirmed_only_helper.tr(),
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
