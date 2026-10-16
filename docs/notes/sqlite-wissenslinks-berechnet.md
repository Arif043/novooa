# Wissenslinks werden beim Lesen berechnet (0019)

> `knowledge_notes` speichert keine Linkprojektion; ausgehende Links entstehen beim Lesen aus Markdown und aktuellen IDs, Titeln und Pfaden.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Gilt für API und Workflow-Store, jeweils innerhalb derselben Wissensbasis
  im selben Team.
- Umbenennungen und Löschungen sind dadurch sofort berücksichtigt.
- Exporte enthalten nur maßgebliche Notizfelder; nach dem Import werden Links
  gegen den vollständigen Zielbestand aufgelöst.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Wissensbasis](../features/wissensbasis.md)
