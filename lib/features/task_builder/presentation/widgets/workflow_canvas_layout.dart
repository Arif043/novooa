import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/entities/workflow_node_outputs.dart';
import '../../domain/entities/workflow_output_types.dart';

class BausteinInsertion {
  const BausteinInsertion({this.owner, this.branchId, this.after});
  final NodeId? owner;
  final String? branchId;
  final NodeId? after;
}

/// Wohin eine Doppelklick-Umbenennung eines Leinwand-Labels fachlich
/// abzielt — `null` (kein [CanvasLabel.editTarget]) heißt: rein
/// strukturelles Label (z.B. "Für jedes Element"), nicht editierbar.
sealed class CanvasLabelEditTarget {
  const CanvasLabelEditTarget();
}

/// Der primäre Ausgabename eines Bausteins mit genau einem fachlichen
/// Output (die meisten Primitives).
class OutputNameEditTarget extends CanvasLabelEditTarget {
  const OutputNameEditTarget(this.nodeId);
  final NodeId nodeId;
}

/// Ein einzelnes Feld einer strukturierten Prompt-Ausgabe — [fieldIndex]
/// ist der Original-Index in `PromptNodeConfig.structuredFields`, nicht der
/// Index in der (leere Namen herausfilternden) Chip-Liste.
class StructuredFieldEditTarget extends CanvasLabelEditTarget {
  const StructuredFieldEditTarget(this.nodeId, this.fieldIndex);
  final NodeId nodeId;
  final int fieldIndex;
}

/// Ein einzelnes Feld einer Dialogeingabe — [fieldIndex] wie bei
/// [StructuredFieldEditTarget] der Original-Index in
/// `DialogInputNodeConfig.fields`.
class DialogFieldEditTarget extends CanvasLabelEditTarget {
  const DialogFieldEditTarget(this.nodeId, this.fieldIndex);
  final NodeId nodeId;
  final int fieldIndex;
}

/// Das Label eines Zweigs eines Bedingter-Ablauf-Bausteins (z.B. "Ja").
class ConditionalBranchEditTarget extends CanvasLabelEditTarget {
  const ConditionalBranchEditTarget(this.conditionalNodeId, this.branchId);
  final NodeId conditionalNodeId;
  final String branchId;
}

/// Ein einzelner Chip-Text auf einem Leinwand-Pfeil, optional editierbar
/// (siehe [CanvasLabelEditTarget]).
class CanvasLabel {
  const CanvasLabel(this.text, [this.editTarget, this.type]);
  final String text;
  final CanvasLabelEditTarget? editTarget;

  /// Typ des Ausgabewerts, den das Label benennt — steuert Farbe und Icon.
  /// `null` bei Bedingungs- und strukturellen Labels.
  final NodeOutputType? type;
}

class CanvasEntry {
  const CanvasEntry(
    this.id,
    this.node,
    this.insertion,
    this.peers, {
    this.continuationLabel,
    this.canInsert = true,
  });
  final String id;
  final WorkflowNode? node;
  final BausteinInsertion insertion;
  final Set<NodeId> peers;
  final String? continuationLabel;
  final bool canInsert;
}

class CanvasLink {
  const CanvasLink(
    this.from,
    this.to, [
    this.labels = const [],
    this.isReturn = false,
    this.isCondition = false,
  ]);
  final String from;
  final String to;

  /// Chips auf dem Pfeil — normalerweise höchstens einer (Bedingungs-Label
  /// wie "Ja"/"Nein" oder der Referenzname des Zielbausteins), bei mehreren
  /// fachlichen Ausgabewerten eines Bausteins (z.B. strukturierte Prompt-
  /// Ausgabe mit mehreren Feldern) aber auch mehrere.
  final List<CanvasLabel> labels;
  final bool isReturn;

  /// Unterscheidet Bedingungs-/Verzweigungs-Labels (z.B. "Ja"/"Nein",
  /// "Für jedes Element") von fachlichen Workflow-Ausgabewerten — beide
  /// werden als Chip dargestellt, aber mit unterschiedlicher Hintergrundfarbe
  /// (siehe [WorkflowEdgesPainter._paintLabels]).
  final bool isCondition;
}

/// Presentation-only layout: persisted edges remain the source of truth.
/// Containment links additionally make conditional and loop subplans visible.
class WorkflowCanvasLayout {
  WorkflowCanvasLayout(WorkflowGraph graph, {double textScale = 1})
    : nodeHeight = cardHeight * textScale.clamp(1.0, 3.0) {
    _collect(graph, const BausteinInsertion());
    _arrange();
  }

  static const cardWidth = 340.0;
  static const cardHeight = 120.0;
  static const _baseRowGap = 100.0;

  /// Zusätzlicher Platzbedarf pro weiterem, untereinander gestapeltem Chip
  /// auf einem Pfeil (siehe [WorkflowEdgesPainter._paintLabels]) — grobe
  /// Schätzung aus Chip-Höhe und -Abstand, da das Layout selbst keine
  /// Textmetriken kennt.
  static const _labelStackHeight = 34.0;
  final double nodeHeight;
  final entries = <String, CanvasEntry>{};
  final links = <CanvasLink>[];
  final rectangles = <String, Rect>{};
  late final Size size;

  List<String> _collect(
    WorkflowGraph graph,
    BausteinInsertion insertion, {
    String? parent,
    String? label,
    CanvasLabelEditTarget? labelEditTarget,
  }) {
    final peers = graph.nodes.map((node) => node.id).toSet();
    if (graph.nodes.isEmpty) {
      final id = '@empty:${parent ?? 'main'}:${insertion.branchId ?? ''}';
      entries[id] = CanvasEntry(id, null, insertion, peers);
      if (parent != null) {
        links.add(
          CanvasLink(
            parent,
            id,
            _labelList(label, labelEditTarget),
            false,
            true,
          ),
        );
      }
      return [id];
    }
    for (final node in graph.nodes) {
      entries[node.id.value] = CanvasEntry(
        node.id.value,
        node,
        BausteinInsertion(
          owner: insertion.owner,
          branchId: insertion.branchId,
          after: node.id,
        ),
        peers,
      );
    }
    for (final edge in graph.edges) {
      if (peers.contains(edge.from) && peers.contains(edge.to)) {
        final fromNode = graph.nodeOrNull(edge.from)!;
        links.add(
          CanvasLink(
            _exitId(fromNode),
            edge.to.value,
            edge.conditionLabel != null
                ? [CanvasLabel(edge.conditionLabel!)]
                : _outputLabels(fromNode),
            false,
            edge.conditionLabel != null,
          ),
        );
      }
    }
    if (parent != null) {
      final roots = graph.nodes.where(
        (node) => !graph.edges.any((edge) => edge.to == node.id),
      );
      for (final root in roots) {
        links.add(
          CanvasLink(
            parent,
            root.id.value,
            _labelList(label, labelEditTarget),
            false,
            true,
          ),
        );
      }
    }
    for (final node in graph.nodes) {
      final branchEnds = <String>[];
      switch (node.config) {
        case ConditionalNodeConfig(:final branches):
          for (final branch in branches) {
            branchEnds.addAll(
              _collect(
                branch.graph,
                BausteinInsertion(owner: node.id, branchId: branch.id),
                parent: node.id.value,
                label: branch.label,
                labelEditTarget: ConditionalBranchEditTarget(
                  node.id,
                  branch.id,
                ),
              ),
            );
          }
        case ForEachNodeConfig(:final graph):
          branchEnds.addAll(
            _collect(
              graph,
              BausteinInsertion(owner: node.id),
              parent: node.id.value,
              label: LocaleKeys.ui_fuer_jedes_element.tr(),
            ),
          );
        default:
          break;
      }
      if (_exitId(node) != node.id.value) {
        final id = _exitId(node);
        entries[id] = CanvasEntry(
          id,
          null,
          entries[node.id.value]!.insertion,
          peers,
          continuationLabel: node.config is ConditionalNodeConfig
              ? LocaleKeys.ui_after_condition.tr()
              : LocaleKeys.ui_after_loop.tr(),
          canInsert: !graph.edges.any(
            (edge) => edge.from == node.id && peers.contains(edge.to),
          ),
        );
        for (final end in branchEnds.isEmpty ? [node.id.value] : branchEnds) {
          links.add(CanvasLink(end, id, const [], true));
        }
      }
    }
    final ends = <String>[];
    for (final node in graph.nodes) {
      if (graph.edges.any(
        (edge) => edge.from == node.id && peers.contains(edge.to),
      )) {
        continue;
      }
      if (_exitId(node) != node.id.value) {
        ends.add(_exitId(node));
      } else {
        final id = '@append:${node.id.value}';
        entries[id] = CanvasEntry(
          id,
          null,
          entries[node.id.value]!.insertion,
          peers,
        );
        links.add(CanvasLink(node.id.value, id));
        ends.add(id);
      }
    }
    return ends;
  }

  String _exitId(WorkflowNode node) => switch (node.config) {
    ConditionalNodeConfig() ||
    ForEachNodeConfig() => '@continue:${node.id.value}',
    _ => node.id.value,
  };

  /// Fachliche Workflow-Ausgabewerte eines Bausteins als Chips auf seinem
  /// Ausgangspfeil — analog zu den "Ja"/"Nein"-Chips verzweigender
  /// Primitives. Die meisten Bausteine haben genau einen fachlichen
  /// Ausgabewert (Chip = eigener Ausgabename); ein Prompt-Baustein mit
  /// strukturierter Ausgabe oder eine Dialogeingabe haben dagegen mehrere,
  /// eigenständig benannte Ausgabewerte — jeweils ein Chip pro Feld, ohne
  /// umschließenden Knotennamen.
  List<CanvasLabel> _outputLabels(WorkflowNode node) {
    if (node.config case PromptNodeConfig(
      outputType: PromptOutputType.structured,
      :final structuredFields,
    )) {
      return _fieldLabels(
        structuredFields.map(
          (field) =>
              (name: field.name, type: structuredFieldOutputType(field.type)),
        ),
        (index) => StructuredFieldEditTarget(node.id, index),
      );
    }
    if (node.config case final ScriptNodeConfig config
        when hasFlatOutputFields(config)) {
      // Die Namen stehen im Code (`workflow_output(…)`) — auf der Leinwand
      // nur anzeigen, nicht umbenennen.
      return [
        for (final output in scriptWorkflowOutputsOf(config))
          CanvasLabel(output.name, null, output.type),
      ];
    }
    if (node.config case DialogInputNodeConfig(:final fields)) {
      return _fieldLabels(
        fields.map(
          (field) =>
              (name: field.name, type: dialogFieldOutputType(field.type)),
        ),
        (index) => DialogFieldEditTarget(node.id, index),
      );
    }
    return _labelList(
      node.outputName.isEmpty ? null : node.outputName,
      OutputNameEditTarget(node.id),
      primaryOutputTypeOf(node.config),
    );
  }

  /// Wie [_labelList], aber für mehrere, unabhängig benannte Felder — leere
  /// Namen werden für die Anzeige herausgefiltert, das Edit-Ziel trägt aber
  /// weiterhin den echten Original-Index in `names` (nicht den Index in der
  /// gefilterten Ergebnisliste).
  List<CanvasLabel> _fieldLabels(
    Iterable<TypedOutputField> fields,
    CanvasLabelEditTarget Function(int fieldIndex) editTargetFor,
  ) {
    final labels = <CanvasLabel>[];
    var index = 0;
    for (final field in fields) {
      final trimmed = field.name.trim();
      if (trimmed.isNotEmpty) {
        labels.add(CanvasLabel(trimmed, editTargetFor(index), field.type));
      }
      index++;
    }
    return labels;
  }

  List<CanvasLabel> _labelList(
    String? label, [
    CanvasLabelEditTarget? target,
    NodeOutputType? type,
  ]) => label == null ? const [] : [CanvasLabel(label, target, type)];

  void _arrange() {
    final remaining = entries.keys.toSet();
    final levels = <String, int>{};
    while (remaining.isNotEmpty) {
      final ready = remaining
          .where(
            (id) => !links.any(
              (edge) => edge.to == id && remaining.contains(edge.from),
            ),
          )
          .toList();
      // Imported cycles still need a finite, inspectable layout.
      if (ready.isEmpty) ready.add(remaining.first);
      for (final id in ready) {
        var level = 0;
        for (final edge in links.where((edge) => edge.to == id)) {
          if (levels.containsKey(edge.from)) {
            level = math.max(level, levels[edge.from]! + 1);
          }
        }
        levels[id] = level;
        remaining.remove(id);
      }
    }
    _arrangeLanes(levels);
  }

  /// Vertikaler Abstand nach der Reihe [level] — wächst mit der Anzahl
  /// untereinander gestapelter Chips auf einem aus dieser Reihe
  /// herausführenden Pfeil, damit die Pfeillinie sichtbar bleibt statt vom
  /// Chip-Stapel verdeckt zu werden.
  double _rowGap(int level, Map<String, int> levels) {
    var maxLabelCount = 1;
    for (final link in links) {
      if (link.isReturn || link.labels.length <= maxLabelCount) continue;
      final fromLevel = levels[link.from];
      final toLevel = levels[link.to];
      if (fromLevel == null ||
          fromLevel != level ||
          toLevel == null ||
          toLevel <= fromLevel) {
        continue;
      }
      maxLabelCount = link.labels.length;
    }
    return _baseRowGap + (maxLabelCount - 1) * _labelStackHeight;
  }

  void _arrangeLanes(Map<String, int> levels) {
    double heightOf(String id) =>
        entries[id]!.canInsert ? nodeHeight : nodeHeight / cardHeight * 32;
    final rowHeights = <int, double>{};
    for (final entry in levels.entries) {
      rowHeights[entry.value] = math.max(
        rowHeights[entry.value] ?? 0,
        heightOf(entry.key),
      );
    }
    final rowTops = <int, double>{};
    var top = 90.0;
    for (final level in rowHeights.keys.toList()..sort()) {
      rowTops[level] = top;
      top += rowHeights[level]! + _rowGap(level, levels);
    }
    final successors = <String, List<String>>{};
    final continuations = <String, String>{};
    for (final edge in links.where((edge) => !edge.isReturn)) {
      (successors[edge.from] ??= []).add(edge.to);
    }
    for (final entry in entries.values) {
      if (entry.continuationLabel != null) {
        continuations[entry.insertion.after!.value] = entry.id;
      }
    }
    final incoming = <String>{
      ...successors.values.expand((ids) => ids),
      ...continuations.values,
    };
    final children = <String, List<String>>{};
    final visited = <String>{};
    final roots = <String>[];
    // A spanning forest handles shared successors and imported cycles without
    // duplicating cards. Return edges affect vertical order, never path lanes.
    void visit(String id) {
      visited.add(id);
      children[id] = [];
      for (final next in [
        ...?successors[id],
        if (continuations[id] case final String next) next,
      ]) {
        if (visited.contains(next)) continue;
        children[id]!.add(next);
        visit(next);
      }
    }

    for (final id in [
      ...entries.keys.where((id) => !incoming.contains(id)),
      ...entries.keys,
    ]) {
      if (visited.contains(id)) continue;
      roots.add(id);
      visit(id);
    }
    final spans = <String, double>{};
    double measure(String id) {
      var branches = 0.0;
      var continuation = 0.0;
      for (final child in children[id]!) {
        final span = measure(child);
        if (child == continuations[id]) {
          continuation = span;
        } else {
          branches += span;
        }
      }
      return spans[id] = math.max(1.0, math.max(branches, continuation));
    }

    final total = roots.fold(0.0, (sum, id) => sum + measure(id));
    final width = math.max(720.0, total * 390 + 100);
    void place(String id, double center) {
      rectangles[id] = Rect.fromLTWH(
        center - cardWidth / 2,
        rowTops[levels[id]]!,
        cardWidth,
        heightOf(id),
      );
      final branches = children[id]!
          .where((child) => child != continuations[id])
          .toList();
      final span = branches.fold(0.0, (sum, child) => sum + spans[child]!);
      var left = center - span * 390 / 2;
      for (final child in branches) {
        place(child, left + spans[child]! * 390 / 2);
        left += spans[child]! * 390;
      }
      final continuation = continuations[id];
      if (continuation != null && children[id]!.contains(continuation)) {
        place(continuation, center);
      }
    }

    var left = (width - total * 390) / 2;
    for (final root in roots) {
      place(root, left + spans[root]! * 390 / 2);
      left += spans[root]! * 390;
    }
    size = Size(width, math.max(600, top));
  }
}
