# Luminous-Seitenstil

> Listenseiten wie Zeitplan, Datenbank, Dateien, Fähigkeiten und Mitarbeiter teilen Hintergrund, Spaltenbreite, Ränder und Buttonstil über `LuminousPageTheme` und `PageInsets`.

Gehört zu: [Zeitplan](../index/zeitplan.md)

- `lib/core/theme/luminous_page_theme.dart`: seitenweites `Theme` im
  Designsystem „Luminous Precision“ (Inter, zurückhaltendes Orange, Hintergrund
  `surfaceContainerLowest`). Gefüllte und umrandete Buttons sind gleich groß:
  mindestens 48×48, Radius 12.
- `lib/core/layout/page_insets.dart`: `PageInsets.forWidth` liefert eine
  zentrierte Spalte (höchstens 1000 px) mit Seitenrand 20 bzw. 40 px.
- Kopfzeile: Titel links, Aktionen horizontal rechts in einem `Wrap`, der bei
  wenig Platz umbricht; darunter Untertitel und optional eine Zusammenfassung.
  Gemeinsam als `LuminousPageHeader` (`lib/core/widgets/luminous_page_header.dart`,
  Zeitplan, Datenbank, Fähigkeiten, Mitarbeiter).
- Einträge sind Karten mit Radius 20, Rahmen `outlineVariant` und 12 px
  Abstand: `LuminousCard` (optional antippbar), Kopf `LuminousCardHeading` mit
  getönter Symbolkachel `LuminousIconBadge` oder einem Avatar
  (`lib/core/widgets/luminous_card.dart`, Zeitplan, Datenbank, Fähigkeiten, Mitarbeiter).
- Die obere Leiste der App zeigt auf diesen Seiten keinen Titel, nur Menü und
  Aktionen — der Titel steht schon groß im Kopf (`RootTab.hasPageHeader`).
- Laden und Fehler unter dem Kopf: `LuminousStatusPlaceholder`
  (`lib/core/widgets/luminous_status_placeholder.dart`).

Warum zentral: So wirken die Seiten gleich, und eine Stiländerung gilt
überall. Farben und Abstände kommen aus Theme und `docs/DESIGN.md`.

## Siehe auch

- [Muster für leere Zustände](./leerer-zustand-muster.md)
- [Zeitplan-Seite](./zeitplan-seite.md)
- [Fähigkeiten-Seite](./faehigkeiten-seite.md)
- [Mitarbeiter-Seite](./mitarbeiter-seite.md)
- [Designsystem](../DESIGN.md)
