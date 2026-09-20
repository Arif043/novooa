import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import '../../domain/entities/knowledge_note.dart';

/// Interaction springs preserve the layout instead of starting a new force layout.
class KnowledgeGraphPhysics {
  const KnowledgeGraphPhysics({
    required this.notes,
    required this.canvasSize,
    required this.pinnedNoteId,
    this.restPositions = const {},
  });

  final List<KnowledgeNote> notes;
  final Size canvasSize;
  final String? pinnedNoteId;
  final Map<String, Offset> restPositions;

  /// One fixed 1/60-second step; the view accumulates elapsed frame time.
  bool step(Map<String, Offset> positions, Map<String, Offset> velocities) {
    final displacement = {
      for (final note in notes)
        if (positions.containsKey(note.id))
          note.id:
              positions[note.id]! -
              (restPositions[note.id] ?? positions[note.id]!),
    };
    final neighbours = {for (final id in displacement.keys) id: <String>{}};
    for (final note in notes) {
      for (final target in note.outgoingLinks) {
        if (target == note.id ||
            !neighbours.containsKey(target) ||
            !neighbours.containsKey(note.id)) {
          continue;
        }
        neighbours[note.id]!.add(target);
        neighbours[target]!.add(note.id);
      }
    }
    var moving = false;
    for (final id in displacement.keys) {
      if (id == pinnedNoteId) {
        velocities[id] = Offset.zero;
        continue;
      }
      // Only changes along actual connections transfer movement. Averaging
      // prevents hubs or duplicate/backlinks from multiplying the force.
      var linked = Offset.zero;
      for (final neighbour in neighbours[id]!) {
        linked += displacement[neighbour]! - displacement[id]!;
      }
      if (neighbours[id]!.isNotEmpty) {
        linked /= neighbours[id]!.length.toDouble();
      }
      final force = -displacement[id]! * .055 + linked * .025;
      var velocity = ((velocities[id] ?? Offset.zero) + _limit(force, 2)) * .65;
      velocity = _limit(velocity, 5);
      if (velocity.distance < .025 && force.distance < .015) {
        velocities[id] = Offset.zero;
        continue;
      }
      final current = positions[id]!;
      final next = _clamp(current + velocity);
      // Do not keep accumulating momentum against the canvas boundary.
      velocities[id] = next - current;
      positions[id] = next;
      moving = moving || (next - current).distance > .001;
    }
    return moving;
  }

  Offset _clamp(Offset value) => Offset(
    value.dx.clamp(AppSpacing.section, canvasSize.width - AppSpacing.section),
    value.dy.clamp(AppSpacing.section, canvasSize.height - AppSpacing.section),
  );

  Offset _limit(Offset vector, double limit) =>
      vector.distance > limit ? vector / vector.distance * limit : vector;
}
