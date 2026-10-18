import 'dart:math' as math;
import 'dart:ui';

import 'canvas_link_transition.dart';
import 'workflow_canvas_layout.dart';

export 'canvas_link_transition.dart' show FrameLink;

/// Ein Bild der Leinwand während des Übergangs von einem Layout zum nächsten:
/// Bleibende Bausteine gleiten, neue blenden ein, entfernte (z. B. ein
/// gelöschter Zweig samt Bausteinen) blenden an ihrem alten Platz aus. Kanten
/// bleiben an ihrem Platz ([linksBetween]).
class CanvasFrame {
  CanvasFrame._(
    this.entries,
    this.links,
    this.rectangles,
    this.size,
    this._entryOpacities,
    this.departing,
  );

  /// Das Layout ohne Übergang.
  factory CanvasFrame.of(WorkflowCanvasLayout layout) =>
      CanvasFrame.between(layout, layout, 1);

  /// [progress] läuft von 0 ([from]) bis 1 ([to]).
  factory CanvasFrame.between(
    WorkflowCanvasLayout from,
    WorkflowCanvasLayout to,
    double progress,
  ) {
    final rectangles = <String, Rect>{};
    final opacities = <String, double>{};
    for (final id in to.entries.keys) {
      final before = from.rectangles[id];
      rectangles[id] = before == null
          ? to.rectangles[id]!
          : Rect.lerp(before, to.rectangles[id], progress)!;
      opacities[id] = before == null ? progress : 1;
    }
    final departing = from.entries.keys
        .where((id) => !to.entries.containsKey(id))
        .toSet();
    for (final id in departing) {
      rectangles[id] = from.rectangles[id]!;
      opacities[id] = 1 - progress;
    }
    final links = linksBetween(from, to, progress);
    return CanvasFrame._(
      [...to.entries.values, for (final id in departing) from.entries[id]!],
      links,
      rectangles,
      Size(
        math.max(from.size.width, to.size.width),
        math.max(from.size.height, to.size.height),
      ),
      opacities,
      departing,
    );
  }

  final List<CanvasEntry> entries;
  final List<FrameLink> links;
  final Map<String, Rect> rectangles;
  final Size size;
  final Map<String, double> _entryOpacities;

  /// Bausteine, die es im neuen Layout nicht mehr gibt; sie nehmen keine
  /// Eingaben mehr an.
  final Set<String> departing;

  double opacityOf(String entryId) => _entryOpacities[entryId] ?? 1;
}
