import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import 'branch_condition_comparison_row.dart';
import 'branch_condition_group_box.dart';

/// Rekursiver Editor für einen [BranchCondition]-Ausdrucksbaum — ein
/// [ComparisonCondition]-Blatt wird als Vergleichszeile gerendert
/// ([ComparisonRow]), eine [GroupCondition] als eingerückter Rahmen mit
/// Verknüpfung (AND/OR/XOR) und rekursiv gerenderten Kindern ([GroupBox]).
/// "Klammern" entsteht durch Verschachtelung: jeder Knoten kann sich über
/// [GroupMenuButton] in eine neue [GroupCondition] hüllen lassen, die ihn
/// samt eines neuen leeren Vergleichs enthält.
class BranchConditionEditor extends StatelessWidget {
  const BranchConditionEditor({
    super.key,
    required this.condition,
    required this.graph,
    required this.onChanged,
    this.onRemove,
  });

  final BranchCondition condition;
  final WorkflowGraph graph;
  final ValueChanged<BranchCondition> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return switch (condition) {
      ComparisonCondition comparison => ComparisonRow(
        comparison: comparison,
        graph: graph,
        onChanged: onChanged,
        onRemove: onRemove,
        onGroup: (combinator) => onChanged(_groupedWith(combinator)),
      ),
      GroupCondition group => GroupBox(
        group: group,
        graph: graph,
        onChanged: onChanged,
        onRemove: onRemove,
        onGroup: (combinator) => onChanged(_groupedWith(combinator)),
      ),
    };
  }

  BranchCondition _groupedWith(BooleanCombinator combinator) {
    return GroupCondition(
      combinator: combinator,
      children: [condition, emptyComparisonCondition],
    );
  }
}

/// Der Startzustand eines neu hinzugefügten Vergleichs — überall dort
/// wiederverwendet, wo ein leerer Vergleich neu entsteht (Gruppieren, neue
/// Bedingung in einer Gruppe).
const emptyComparisonCondition = ComparisonCondition(
  left: '',
  operator: ComparisonOperator.equals,
  right: '',
);

/// Icon-Button neben jedem Knoten (Blatt oder Gruppe): hüllt ihn per
/// Klick-Auswahl in eine neue Gruppe mit dem gewählten Verknüpfungstyp —
/// die "Klammer setzen"-Aktion des Baukastens. Von [ComparisonRow] und
/// [GroupBox] gemeinsam genutzt.
class GroupMenuButton extends StatelessWidget {
  const GroupMenuButton({super.key, required this.onSelected});

  final ValueChanged<BooleanCombinator> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BooleanCombinator>(
      tooltip: LocaleKeys.ui_weitere_bedingung_verknuepfen.tr(),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final combinator in BooleanCombinator.values)
          PopupMenuItem(
            value: combinator,
            child: Text(conditionGroupLabel(combinator)),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_add, size: 20),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.ui_verknuepfen.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

String conditionGroupLabel(BooleanCombinator combinator) =>
    switch (combinator) {
      BooleanCombinator.and => LocaleKeys.ui_all_conditions_match.tr(),
      BooleanCombinator.or => LocaleKeys.ui_any_condition_matches.tr(),
      BooleanCombinator.xor => LocaleKeys.ui_exactly_one_condition_matches.tr(),
    };
