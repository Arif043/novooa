# Luminous-Seitenstil

> Listenseiten wie Zeitplan und Dateien teilen Hintergrund, Spaltenbreite, Ränder und Buttonstil über `LuminousPageTheme` und `PageInsets`.

Gehört zu: [Zeitplan](../index/zeitplan.md)

- `lib/core/theme/luminous_page_theme.dart`: seitenweites `Theme` im
  Designsystem „Luminous Precision“ (Inter, zurückhaltendes Orange, Hintergrund
  `surfaceContainerLowest`). Gefüllte und umrandete Buttons sind gleich groß:
  mindestens 48×48, Radius 12.
- `lib/core/layout/page_insets.dart`: `PageInsets.forWidth` liefert eine
  zentrierte Spalte (höchstens 1000 px) mit Seitenrand 20 bzw. 40 px.
- Kopfzeile: Titel links, Aktionen horizontal rechts in einem `Wrap`, der bei
  wenig Platz umbricht. Einträge sind Karten mit Radius 16, Rahmen
  `outlineVariant` und 12 px Abstand.

Warum zentral: So wirken beide Seiten gleich, und eine Stiländerung gilt
überall. Farben und Abstände kommen aus Theme und `docs/DESIGN.md`.

## Siehe auch

- [Muster für leere Zustände](./leerer-zustand-muster.md)
- [Zeitplan-Seite](./zeitplan-seite.md)
- [Designsystem](../DESIGN.md)
