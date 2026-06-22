import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

/// Feature-spezifischer App-Bar für den Aufgaben-Builder.
///
/// Aufbau: links Branding (Titel + Subtitel), mittig horizontale
/// Tab-Navigation mit den sechs [WorkflowPrimitive]-Werten, rechts
/// Hilfemenü + Settings + Avatar-Platzhalter.
///
/// Tippen auf einen Tab fügt den entsprechenden Baustein am Ende des
/// Flows ein. Der Tab des aktuell selektierten Knotens wird optisch
/// hervorgehoben.
class TaskBuilderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TaskBuilderAppBar({
    super.key,
    required this.activePrimitive,
    required this.onPrimitiveTab,
  });

  final WorkflowPrimitive? activePrimitive;
  final ValueChanged<WorkflowPrimitive> onPrimitiveTab;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyscatTheme.glassSurfaceSoft,
        border: Border(
          bottom: BorderSide(color: SyscatTheme.borderLight),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            const _Brand(),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _PrimitiveTabBar(
                active: activePrimitive,
                onTap: onPrimitiveTab,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            const _Trailing(),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bausteine Builder',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          'Workflow Studio',
          style: TextStyle(
            fontSize: 11,
            color: SyscatTheme.primaryOrangeDark,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _PrimitiveTabBar extends StatelessWidget {
  const _PrimitiveTabBar({required this.active, required this.onTap});

  final WorkflowPrimitive? active;
  final ValueChanged<WorkflowPrimitive> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final primitive in WorkflowPrimitive.values) ...[
            _PrimitiveTab(
              primitive: primitive,
              selected: primitive == active,
              onTap: () => onTap(primitive),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _PrimitiveTab extends StatelessWidget {
  const _PrimitiveTab({
    required this.primitive,
    required this.selected,
    required this.onTap,
  });

  final WorkflowPrimitive primitive;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? SyscatTheme.primaryOrangeHover
        : Colors.transparent;
    final foreground = selected
        ? SyscatTheme.primaryOrangeDark
        : SyscatTheme.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: '${primitive.label} hinzufügen',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(primitive), size: 14, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  primitive.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
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

class _Trailing extends StatelessWidget {
  const _Trailing();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Hilfe',
          onPressed: () {},
          icon: const Icon(Icons.help_outline, size: 20),
        ),
        IconButton(
          tooltip: 'Einstellungen',
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
        const SizedBox(width: AppSpacing.xs),
        const _Avatar(),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SyscatTheme.activeNavigationGradient,
      ),
      alignment: Alignment.center,
      child: const Text(
        'JB',
        style: TextStyle(
          color: SyscatTheme.textMainLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}