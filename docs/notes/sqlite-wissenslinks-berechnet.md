# Wissenslinks werden beim Lesen berechnet (0019)

> `knowledge_notes` speichert keine Linkprojektion; ausgehende Links entstehen beim Lesen aus Markdown und aktuellen IDs, Titeln und Pfaden.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md) · [Wissensbasis](../index/wissensbasis.md)

- Gilt für API und Workflow-Store, jeweils innerhalb derselben Wissensbasis
  im selben Team.
- Der Domain-Service `knowledgeLinksFrom` berechnet die IDs; der lokale
  Client sendet nur Titel, Pfad und Inhalt, `outgoingLinks` ist ein
  berechnetes Antwortfeld.
- Anlage, Umbenennung, Pfadänderung oder Löschung einer Zielnotiz wirkt beim
  nächsten Lesen auf alle Quellen, ohne deren Inhalt neu zu speichern.
- Exporte enthalten nur maßgebliche Notizfelder; nach dem Import werden Links
  gegen den vollständigen Zielbestand aufgelöst.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Wissensbasis](../index/wissensbasis.md)
