# Wissensgraph

> Die Graph-Ansicht zeigt Notizen als verschiebbare Punkte und ihre Links als feine Linien; verbundene Knoten folgen beim Ziehen federnd.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

- Kanten aus `outgoingLinks`; Klick auf einen Knoten wählt die Notiz im
  Editor.
- Ruhige Canvas im Hell-/Dunkelmodus, organisch verteilte Knoten, gedämpfte
  Linien, dezente Labels, Pan/Zoom, Overlay-Leiste zum Zurücksetzen.
- Ziehen: Verbundene Knoten bewegen sich federnd mit und kehren gedämpft
  zurück; der gezogene bleibt am Ablagepunkt; unverbundene werden nicht
  abgestoßen.
- Physik mit festen Zeitschritten und der bestehenden Anordnung als
  Ruheposition, statt die Kräfte global neu zu verteilen.
- Reduzierte Bewegung: direkte Positionierung ohne Federanimation.

## Siehe auch

- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md)
- [Wissensbasis-Seite](./wissensbasis-seite.md)
