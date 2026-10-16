# Firestore im Client

> Sichtbarer Firestore-Zustand kommt über Repository-Streams; im Web hält ein persistenter IndexedDB-Cache Daten auch offline verfügbar.

Gehört zu: [Architektur](../index/architektur.md)

- Veränderlicher Zustand über `watch*`-Streams; Cubits halten ihre
  Subscription nur für ihre Lebensdauer und kündigen sie in `close()`.
  Einmalige `get()`-Reads nur für Schreibabläufe, Transaktionen und
  Mutationsrückgaben.
- Web: persistenter IndexedDB-Cache mit Multi-Tab-Synchronisierung — nur auf
  vertrauenswürdigen Geräten verwenden.
- Ein globaler Netzstatus zeigt offline dauerhaft eine Snackbar; Repositories
  liefern weiter gecachte Snapshots.
- Die Team-ID wird vor jeder team-scoped Abfrage per normalem Read mit
  Cache-Fallback aufgelöst. Eine Transaktion nur beim erstmaligen Anlegen
  des Arbeitsbereichs, weil Transaktionen offline nicht laufen.
- Live-Abfragen basieren auf `watchCurrentTeamId()`; ändert sich `teamId`, wird
  die alte Sammlung abgemeldet und die neue abonniert.

## Siehe auch

- [Team-Kontext und Einladungen](./team-kontext.md)
- [Firestore-Pfade](./firestore-pfade.md)
