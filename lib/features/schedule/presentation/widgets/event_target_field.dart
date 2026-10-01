import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';
import 'event_target_labels.dart';

/// Ein einzelnes Feld für das Ziel eines Ereignisses. Der Standard ist
/// „Überall"; Tippen öffnet die Auswahl.
class EventTargetField extends StatelessWidget {
  const EventTargetField({
    super.key,
    required this.scope,
    required this.target,
    required this.onTap,
  });

  final EventTargetScope scope;
  final EventTriggerTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = eventTargetFieldLabel(scope);
    final value = eventTargetLabel(target);
    return Semantics(
      button: true,
      label: '$label $value. Auswahl öffnen',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Text(value, maxLines: 2)),
                const Icon(Icons.unfold_more),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
