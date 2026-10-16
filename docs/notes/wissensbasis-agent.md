# Wissensbasis-Agent

> Der Wissensbasis-Agent sucht und liest team-begrenzt Notizen, ändert aber nichts selbst; Änderungen schlägt er als `knowledgeCommands` vor.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- Tools: `searchKnowledgeNotes`, `readKnowledgeNote`, `extractPageLinks`
  plus URL Context. Der Team-Scope kommt serverseitig aus dem Laufzeitkontext
  (`GetCurrentTeamId`); teamfremde IDs werden nicht angenommen.
- Tool-Definitionen und HTTP/HTML-Adapter liegen unter
  `knowledge_base/infrastructure/genkit`; Cloud verdrahtet Firestore und
  Firebase Auth, die Runtime SQLite und lokale Identität.
- Notizinhalte sind untrusted Kontext und können die Systemanweisungen nicht
  überschreiben; deshalb hat er keine schreibenden Tools.
- Vorschläge erscheinen als Plan; nach **Ausführen** liefert jede Änderung
  eine Rückgängig-Aktion: Erstellen → löschen, Bearbeiten → vorherigen Stand
  wiederherstellen, Löschen → mit derselben ID wiederherstellen.
- Cloud Logging protokolliert vorgeschlagene Commands (UID, Aktionstyp,
  Label, Titel, ggf. Notiz-ID), nie Chattext oder Notizinhalte.

## Siehe auch

- [URL Context und Seitenlinks](./url-context-und-seitenlinks.md)
- [Wo die KI-Agenten laufen](./ki-agenten-betriebsorte.md)
- [Wissensbasis](../features/wissensbasis.md)
