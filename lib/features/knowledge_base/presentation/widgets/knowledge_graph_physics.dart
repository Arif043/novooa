import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';

class KnowledgeGraphPhysics {
  const KnowledgeGraphPhysics({
    required this.notes,
    required this.canvasSize,
    required this.pinnedNoteId,
  });

  final List<KnowledgeNote> notes;
  final Size canvasSize;
  final String? pinnedNoteId;

  bool step(Map<String, Offset> positions, Map<String, Offset> velocities) {
    final forces = {for (final note in notes) note.id: Offset.zero};
    _applyRepulsion(positions, forces);
    _applyLinks(positions, forces);
    _applyCenterGravity(positions, forces);
    return _integrate(positions, velocities, forces);
  }

  void _applyRepulsion(
    Map<String, Offset> positions,
    Map<String, Offset> forces,
  ) {
    for (final a in notes) {
      for (final b in notes) {
        if (a.id == b.id) continue;
        final vector = positions[a.id]! - positions[b.id]!;
        final distance = math.max(vector.distance, 24.0);
        forces[a.id] = forces[a.id]! + vector / distance * (720 / distance);
      }
    }
  }

  void _applyLinks(Map<String, Offset> positions, Map<String, Offset> forces) {
    final noteIds = notes.map((note) => note.id).toSet();
    for (final note in notes) {
      for (final targetId in note.outgoingLinks.where(noteIds.contains)) {
        final vector = positions[targetId]! - positions[note.id]!;
        final distance = math.max(vector.distance, 1.0);
        final force = vector / distance * ((distance - 150) * 0.018);
        forces[note.id] = forces[note.id]! + force;
        forces[targetId] = forces[targetId]! - force;
      }
    }
  }

  void _applyCenterGravity(
    Map<String, Offset> positions,
    Map<String, Offset> forces,
  ) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    for (final note in notes) {
      forces[note.id] =
          forces[note.id]! + (center - positions[note.id]!) * 0.002;
    }
  }

  bool _integrate(
    Map<String, Offset> positions,
    Map<String, Offset> velocities,
    Map<String, Offset> forces,
  ) {
    var moving = false;
    for (final note in notes) {
      if (note.id == pinnedNoteId) {
        velocities[note.id] = Offset.zero;
        continue;
      }
      final velocity =
          ((velocities[note.id] ?? Offset.zero) + forces[note.id]!) * 0.82;
      velocities[note.id] = velocity;
      positions[note.id] = _clamp(positions[note.id]! + velocity);
      moving = moving || velocity.distance > 0.08;
    }
    return moving;
  }

  Offset _clamp(Offset value) {
    return Offset(
      value.dx.clamp(AppSpacing.section, canvasSize.width - AppSpacing.section),
      value.dy.clamp(
        AppSpacing.section,
        canvasSize.height - AppSpacing.section,
      ),
    );
  }
}
