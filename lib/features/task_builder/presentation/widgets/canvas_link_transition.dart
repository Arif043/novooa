import 'dart:ui';

import 'workflow_canvas_layout.dart';

/// Eine Kante in einem Zwischenbild: ihre Endpunkte (Karten-Rechtecke) und wie
/// sichtbar sie gerade ist.
class FrameLink {
  const FrameLink(this.link, this.from, this.to, this.opacity);

  final CanvasLink link;
  final Rect from;
  final Rect to;
  final double opacity;
}

/// Ordnet die Kanten zweier Layouts über ihre Plätze zu, nicht über die IDs.
///
/// Nimmt ein Baustein den Platz eines anderen ein (Tausch), bleibt die Kante
/// an diesem Platz stehen, während die Karten tauschen; sie fliegt nicht mit
/// der Karte quer über die Leinwand. Kanten ohne Gegenstück blenden an ihrem
/// Platz ein bzw. aus.
List<FrameLink> linksBetween(
  WorkflowCanvasLayout from,
  WorkflowCanvasLayout to,
  double progress,
) {
  final slots = _slotsOf(from, to);
  String slotKey(CanvasLink link) =>
      '${slots[link.from] ?? link.from}>${slots[link.to] ?? link.to}';
  final oldLinks = {
    for (final link in from.links) '${link.from}>${link.to}': link,
  };
  final matched = <String>{};
  final links = <FrameLink>[];
  for (final link in to.links) {
    final old = oldLinks[slotKey(link)];
    if (old != null) matched.add(slotKey(link));
    links.add(
      FrameLink(
        link,
        _lerp(
          old == null ? null : from.rectangles[old.from],
          to.rectangles[link.from]!,
          progress,
        ),
        _lerp(
          old == null ? null : from.rectangles[old.to],
          to.rectangles[link.to]!,
          progress,
        ),
        old == null ? progress : 1,
      ),
    );
  }
  for (final entry in oldLinks.entries) {
    if (matched.contains(entry.key)) continue;
    final link = entry.value;
    links.add(
      FrameLink(
        link,
        from.rectangles[link.from]!,
        from.rectangles[link.to]!,
        1 - progress,
      ),
    );
  }
  return links;
}

Rect _lerp(Rect? before, Rect after, double progress) =>
    before == null ? after : Rect.lerp(before, after, progress)!;

/// Welcher alte Platz jetzt von welchem Baustein belegt ist: Ein Baustein,
/// dessen neues Rechteck am alten Rechteck eines anderen liegt, hat dessen
/// Platz übernommen. Sonst behält er seinen eigenen.
Map<String, String> _slotsOf(
  WorkflowCanvasLayout from,
  WorkflowCanvasLayout to,
) {
  final slots = <String, String>{};
  for (final entry in to.rectangles.entries) {
    final own = from.rectangles[entry.key];
    if (own == null || own == entry.value) continue;
    final nearest = _nearestOldEntry(from, entry.value.center);
    if (nearest != null && nearest != entry.key) slots[entry.key] = nearest;
  }
  return slots;
}

const _slotTolerance = 40.0;

String? _nearestOldEntry(WorkflowCanvasLayout from, Offset center) {
  String? nearest;
  var distance = _slotTolerance;
  for (final entry in from.rectangles.entries) {
    final candidate = (entry.value.center - center).distance;
    if (candidate >= distance) continue;
    distance = candidate;
    nearest = entry.key;
  }
  return nearest;
}
