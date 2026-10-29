# Wissensbasis-Agent

> Der Wissensbasis-Agent sucht und liest team-begrenzt Notizen, ändert aber nichts selbst; Änderungen schlägt er als `knowledgeCommands` vor.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- Tools: `listKnowledgeNoteTitles` (alle Titel mit Zahl der Links und
  Rückverweise, ohne Inhalt, höchstens 500), `searchKnowledgeNotes` (alle
  Notizen des Teams, Titeltreffer zuerst, höchstens 20),
  `readKnowledgeNote` (Inhalt samt `links` und `backlinks`), `extractPageLinks`
  plus URL Context. Der Team-Scope kommt serverseitig aus dem Laufzeitkontext
  (`GetCurrentTeamId`); teamfremde IDs werden nicht angenommen.
- Tool-Definitionen und HTTP/HTML-Adapter liegen unter
  `knowledge_base/infrastructure/genkit`; die Runtime verdrahtet SQLite und
  ihre Sitzungsidentität.
- Der fachliche Vertrag `KnowledgeBaseAssistant` ist laufzeitneutral.
- Notizinhalte sind untrusted Kontext und können die Systemanweisungen nicht
  überschreiben; deshalb hat er keine schreibenden Tools.
- Notizen schlägt er nach den
  [Zettelkasten-Regeln](./wissensbasis-agent-zettelkasten.md) vor; genutzte
  Notizen nennt er in Antworten als anklickbare `[[Titel]]`.
- Vorschläge erscheinen als Plan; nach **Ausführen** liefert jede Änderung
  eine Rückgängig-Aktion: Erstellen → löschen, Bearbeiten → vorherigen Stand
  wiederherstellen, Löschen → mit derselben ID wiederherstellen.

## Siehe auch

- [Zettelkasten-Regeln des Wissensbasis-Agenten](./wissensbasis-agent-zettelkasten.md)
- [URL Context und Seitenlinks](./url-context-und-seitenlinks.md)
- [Wo die KI-Agenten laufen](./ki-agenten-betriebsorte.md)
- [Wissensbasis-Seite](./wissensbasis-seite.md)
