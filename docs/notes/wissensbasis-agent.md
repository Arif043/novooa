# Wissensbasis-Agent

> Der Wissensbasis-Agent sucht und liest team-begrenzt Notizen, ändert aber nichts selbst; Änderungen schlägt er als `knowledgeCommands` vor.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- Tools: `searchKnowledgeNotes`, `readKnowledgeNote`, `extractPageLinks`
  plus URL Context. Der Team-Scope kommt serverseitig aus dem Laufzeitkontext
  (`GetCurrentTeamId`); teamfremde IDs werden nicht angenommen.
- Tool-Definitionen und HTTP/HTML-Adapter liegen unter
  `knowledge_base/infrastructure/genkit`; die Runtime verdrahtet SQLite und
  ihre Sitzungsidentität.
- Der fachliche Vertrag `KnowledgeBaseAssistant` ist laufzeitneutral.
- Notizinhalte sind untrusted Kontext und können die Systemanweisungen nicht
  überschreiben; deshalb hat er keine schreibenden Tools.
- Vorschläge erscheinen als Plan; nach **Ausführen** liefert jede Änderung
  eine Rückgängig-Aktion: Erstellen → löschen, Bearbeiten → vorherigen Stand
  wiederherstellen, Löschen → mit derselben ID wiederherstellen.

## Siehe auch

- [URL Context und Seitenlinks](./url-context-und-seitenlinks.md)
- [Wo die KI-Agenten laufen](./ki-agenten-betriebsorte.md)
- [Wissensbasis-Seite](./wissensbasis-seite.md)
