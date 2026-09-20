import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';

class KnowledgeGraphLayout {
  KnowledgeGraphLayout(List<KnowledgeNote> notes, Size size) {
    positions = _ForceLayout(notes: notes, size: size).positions();
  }

  late final Map<String, Offset> positions;
}

class _ForceLayout {
  const _ForceLayout({required this.notes, required this.size});

  final List<KnowledgeNote> notes;
  final Size size;

  Map<String, Offset> positions() {
    if (notes.length == 1) return {notes.first.id: _center};
    final positions = _initialPositions();
    for (var iteration = 0; iteration < 90; iteration++) {
      _applyForces(positions);
    }
    return positions;
  }

  Offset get _center => Offset(size.width / 2, size.height / 2);

  Map<String, Offset> _initialPositions() {
    final radius = math.min(size.width, size.height) * 0.24;
    return {
      for (var index = 0; index < notes.length; index++)
        notes[index].id:
            _center +
            Offset(
              math.cos(index * 2.399) * radius,
              math.sin(index * 2.399) * radius,
            ),
    };
  }

  void _applyForces(Map<String, Offset> positions) {
    final deltas = {for (final note in notes) note.id: Offset.zero};
    _applyRepulsion(positions, deltas);
    _applyLinks(positions, deltas);
    for (final note in notes) {
      final next = positions[note.id]! + deltas[note.id]! * 0.025;
      positions[note.id] = _clamp(next);
    }
  }

  void _applyRepulsion(
    Map<String, Offset> positions,
    Map<String, Offset> deltas,
  ) {
    for (final a in notes) {
      for (final b in notes) {
        if (a.id == b.id) continue;
        final vector = positions[a.id]! - positions[b.id]!;
        final distance = math.max(vector.distance, 16.0);
        deltas[a.id] = deltas[a.id]! + vector / distance * (2200 / distance);
      }
    }
  }

  void _applyLinks(Map<String, Offset> positions, Map<String, Offset> deltas) {
    final noteIds = notes.map((note) => note.id).toSet();
    for (final note in notes) {
      for (final targetId in note.outgoingLinks.where(noteIds.contains)) {
        final vector = positions[targetId]! - positions[note.id]!;
        final force = vector * 0.012;
        deltas[note.id] = deltas[note.id]! + force;
        deltas[targetId] = deltas[targetId]! - force;
      }
    }
  }

  Offset _clamp(Offset value) {
    return Offset(
      value.dx.clamp(AppSpacing.section, size.width - AppSpacing.section),
      value.dy.clamp(AppSpacing.section, size.height - AppSpacing.section),
    );
  }
}

class KnowledgeGraphPainter extends CustomPainter {
  const KnowledgeGraphPainter({
    required this.notes,
    required this.positions,
    required this.colorScheme,
    required this.selectedNoteId,
  });

  final List<KnowledgeNote> notes;
  final Map<String, Offset> positions;
  final ColorScheme colorScheme;
  final String? selectedNoteId;

  @override
  void paint(Canvas canvas, Size size) {
    final noteIds = notes.map((note) => note.id).toSet();
    for (final note in notes) {
      final source = positions[note.id];
      if (source == null) continue;
      for (final linkId in note.outgoingLinks.where(noteIds.contains)) {
        final target = positions[linkId];
        if (target == null) continue;
        canvas.drawLine(
          source + Offset(0, -10),
          target + Offset(0, -10),
          _paintFor(note.id, linkId),
        );
      }
    }
  }

  Paint _paintFor(String sourceId, String targetId) {
    final selected = sourceId == selectedNoteId || targetId == selectedNoteId;
    return Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(
        alpha: selected ? 0.46 : 0.16,
      )
      ..strokeWidth = selected ? 1.7 : 1.1
      ..style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(KnowledgeGraphPainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.positions != positions ||
        oldDelegate.selectedNoteId != selectedNoteId ||
        oldDelegate.colorScheme != colorScheme;
  }
}
