import 'dart:math' as math;
import 'dart:ui';

import 'workflow_canvas_layout.dart';

/// Ein Bild der Leinwand während des Übergangs von einem Layout zum nächsten:
/// Bleibende Bausteine gleiten, neue blenden ein, entfernte (z. B. ein
/// gelöschter Zweig samt Bausteinen) blenden an ihrem alten Platz aus. Kanten
/// folgen denselben Positionen und blenden mit ihren Bausteinen.
class CanvasFrame {
  CanvasFrame._(
    this.entries,
    this.links,
    this.rectangles,
    this.size,
    this._entryOpacities,
    this._linkOpacities,
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
    final links = _linksBetween(from, to, progress);
    return CanvasFrame._(
      [...to.entries.values, for (final id in departing) from.entries[id]!],
      links.keys.toList(),
      rectangles,
      Size(
        math.max(from.size.width, to.size.width),
        math.max(from.size.height, to.size.height),
      ),
      opacities,
      links,
      departing,
    );
  }

  final List<CanvasEntry> entries;
  final List<CanvasLink> links;
  final Map<String, Rect> rectangles;
  final Size size;
  final Map<String, double> _entryOpacities;
  final Map<CanvasLink, double> _linkOpacities;

  /// Bausteine, die es im neuen Layout nicht mehr gibt; sie nehmen keine
  /// Eingaben mehr an.
  final Set<String> departing;

  double opacityOf(String entryId) => _entryOpacities[entryId] ?? 1;

  double linkOpacityOf(CanvasLink link) => _linkOpacities[link] ?? 1;
}

/// Kanten beider Layouts: gleich gebliebene voll, neue blenden ein, alte aus.
Map<CanvasLink, double> _linksBetween(
  WorkflowCanvasLayout from,
  WorkflowCanvasLayout to,
  double progress,
) {
  String key(CanvasLink link) => '${link.from}>${link.to}';
  final before = {for (final link in from.links) key(link)};
  final after = {for (final link in to.links) key(link)};
  return {
    for (final link in to.links)
      link: before.contains(key(link)) ? 1 : progress,
    for (final link in from.links)
      if (!after.contains(key(link))) link: 1 - progress,
  };
}
