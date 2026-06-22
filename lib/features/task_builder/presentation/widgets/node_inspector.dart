import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_edge.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

/// Public-Record-Typ für eine Bedingungs-Edit-Aktion. Wird vom
/// [NodeInspector] an die Page zurückgegeben, wenn der User einen
/// Eintrag in der Bedingungen-Liste ändert.
typedef ConditionEdit = ({NodeId from, NodeId to, String? label});

/// Rechte Spalte: Inspector für den aktuell selektierten Knoten.
///
/// Sechs Sektionen (jeweils optional): aktiver Baustein, Zweck, Genkit-Ziel,
/// Logik-Modus (nur für `conditionalFlow`), Bedingungen (nur für Knoten
/// mit ausgehenden Kanten) und Vorschläge. Wenn kein Knoten selektiert
/// ist, wird ein dezenter Leerzustand gezeigt.
class NodeInspector extends StatelessWidget {
  const NodeInspector({
    super.key,
    required this.taskDefinition,
    required this.onDescriptionChanged,
    required this.onLogicModeChanged,
    required this.onConditionChanged,
  });

  final TaskDefinition taskDefinition;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<LogicMode> onLogicModeChanged;
  final ValueChanged<ConditionEdit> onConditionChanged;

  @override
  Widget build(BuildContext context) {
    final node = taskDefinition.selectedNodeOrNull;
    return Container(
      decoration: BoxDecoration(
        color: SyscatTheme.glassSurfaceSoft,
        border: Border(left: BorderSide(color: SyscatTheme.borderLight)),
      ),
      child: node == null
          ? const _EmptyInspector()
          : _InspectorBody(
              node: node,
              outgoingEdges: taskDefinition.outgoingEdgesOf(node.id),
              onDescriptionChanged: onDescriptionChanged,
              onLogicModeChanged: onLogicModeChanged,
              onConditionChanged: onConditionChanged,
            ),
    );
  }
}

class _EmptyInspector extends StatelessWidget {
  const _EmptyInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Wähle einen Baustein, um ihn zu bearbeiten.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SyscatTheme.textHint,
                fontStyle: FontStyle.italic,
              ),
        ),
      ),
    );
  }
}

class _InspectorBody extends StatelessWidget {
  const _InspectorBody({
    required this.node,
    required this.outgoingEdges,
    required this.onDescriptionChanged,
    required this.onLogicModeChanged,
    required this.onConditionChanged,
  });

  final WorkflowNode node;
  final List<WorkflowEdge> outgoingEdges;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<LogicMode> onLogicModeChanged;
  final ValueChanged<ConditionEdit> onConditionChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionLabel('Aktiver Baustein'),
        const SizedBox(height: AppSpacing.xs),
        _ActiveNodePill(label: node.primitive.label),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Zweck'),
        const SizedBox(height: AppSpacing.xs),
        _DescriptionField(
          initialValue: node.description,
          onChanged: onDescriptionChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Genkit-Ziel'),
        const SizedBox(height: AppSpacing.xs),
        _CodeText(text: _genkitTarget(node.primitive)),
        if (node.primitive == WorkflowPrimitive.conditionalFlow) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionLabel('Logik-Modus'),
          const SizedBox(height: AppSpacing.xs),
          _LogicModeField(
            value: node.logicMode,
            onChanged: onLogicModeChanged,
          ),
        ],
        if (outgoingEdges.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ConditionsSection(
            edges: outgoingEdges,
            onConditionChanged: onConditionChanged,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _SuggestionsSection(),
      ],
    );
  }

  String _genkitTarget(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.prompt => 'ai.generate',
      WorkflowPrimitive.conditionalFlow => 'defineFlow + branch',
      WorkflowPrimitive.iterativeRefinement => 'defineFlow + loop',
      WorkflowPrimitive.toolCall => 'defineTool',
      WorkflowPrimitive.humanApproval => 'checkpoint',
      WorkflowPrimitive.validation => 'schema validation',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}

class _ActiveNodePill extends StatelessWidget {
  const _ActiveNodePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeLightest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SyscatTheme.primaryOrangeLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 16,
              color: SyscatTheme.primaryOrangeDark,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SyscatTheme.primaryOrangeDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionField extends StatefulWidget {
  const _DescriptionField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _DescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Zweck des Bausteins',
      child: TextField(
        controller: _controller,
        maxLines: 4,
        minLines: 3,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: const InputDecoration(
          hintText: 'Was soll an dieser Stelle passieren?',
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _CodeText extends StatelessWidget {
  const _CodeText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SyscatTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SyscatTheme.borderLight),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: SyscatTheme.textSecondary,
        ),
      ),
    );
  }
}

class _LogicModeField extends StatelessWidget {
  const _LogicModeField({required this.value, required this.onChanged});

  final LogicMode value;
  final ValueChanged<LogicMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SyscatTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SyscatTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogicMode>(
          value: value,
          isExpanded: true,
          items: [
            for (final mode in LogicMode.values)
              DropdownMenuItem(
                value: mode,
                child: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: SyscatTheme.textSecondary,
                  ),
                ),
              ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _ConditionsSection extends StatefulWidget {
  const _ConditionsSection({
    required this.edges,
    required this.onConditionChanged,
  });

  final List<WorkflowEdge> edges;
  final ValueChanged<ConditionEdit> onConditionChanged;

  @override
  State<_ConditionsSection> createState() => _ConditionsSectionState();
}

class _ConditionsSectionState extends State<_ConditionsSection> {
  @override
  Widget build(BuildContext context) {
    final totalConditions = widget.edges.length + 1; // +1 für Default-Pfad
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bedingungen ($totalConditions)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final edge in widget.edges)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _ConditionRow(
              key: ValueKey('${edge.from.value}-${edge.to.value}'),
              initialValue: edge.conditionLabel ?? '',
              placeholder: 'Wenn …',
              onChanged: (value) => widget.onConditionChanged(
                (
                  from: edge.from,
                  to: edge.to,
                  label: value.isEmpty ? null : value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConditionRow extends StatefulWidget {
  const _ConditionRow({
    super.key,
    required this.initialValue,
    required this.placeholder,
    required this.onChanged,
  });

  final String initialValue;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  State<_ConditionRow> createState() => _ConditionRowState();
}

class _ConditionRowState extends State<_ConditionRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: SyscatTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SyscatTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(
                fontSize: 13,
                color: SyscatTheme.textSecondary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: SyscatTheme.textHint,
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: () {},
            icon: Icon(
              Icons.edit_outlined,
              size: 16,
              color: SyscatTheme.textHint,
            ),
            visualDensity: VisualDensity.compact,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SyscatTheme.primaryOrangeLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: SyscatTheme.primaryOrangeDark,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Vorschläge verfügbar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SyscatTheme.primaryOrangeDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Logik optimieren'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SyscatTheme.primaryOrangeDark,
                side: BorderSide(color: SyscatTheme.primaryOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}