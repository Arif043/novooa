import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

/// Pillenförmiger Button am Ende des Flows zum Hinzufügen eines Bausteins.
///
/// Wird unter dem `ListView` platziert, damit der User jederzeit einen
/// weiteren Knoten einfügen kann, ohne scrollen zu müssen. Das Tippen
/// öffnet ein [showModalBottomSheet] mit den sechs Primitives.
class AddNodeButton extends StatelessWidget {
  const AddNodeButton({super.key, required this.onPrimitiveAdded});

  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;

  Future<void> _openSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<WorkflowPrimitive>(
      context: context,
      backgroundColor: SyscatTheme.glassSurfaceSoft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baustein wählen',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final primitive in WorkflowPrimitive.values)
                  ListTile(
                    leading: Icon(_iconFor(primitive)),
                    title: Text(primitive.label),
                    subtitle: Text(primitive.description),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(primitive),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      onPrimitiveAdded(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: SyscatTheme.glassSurfaceSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SyscatTheme.borderStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: SyscatTheme.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Baustein hinzufügen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SyscatTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.prompt => Icons.chat_bubble_outline,
      WorkflowPrimitive.conditionalFlow => Icons.account_tree_outlined,
      WorkflowPrimitive.iterativeRefinement => Icons.autorenew,
      WorkflowPrimitive.toolCall => Icons.construction_outlined,
      WorkflowPrimitive.humanApproval => Icons.verified_user_outlined,
      WorkflowPrimitive.validation => Icons.rule,
    };
  }
}