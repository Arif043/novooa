# Zettelkasten-Regeln des Wissensbasis-Agenten

> Der Wissensbasis-Agent schlägt Notizen nach unserer Zettelkasten-Methode vor: atomar, mit sprechendem Titel, über `[[Titel]]` verlinkt und ohne Waisen.

Gehört zu: [Wissensbasis](../index/wissensbasis.md) · [KI-Agent](../index/ki-agent.md)

Die Regeln aus [`docs/README.md`](../README.md) § Zettelkasten-Regeln, übertragen
auf die Wissensbasis (Prompt-Referenz `zettelkasten` in
`knowledge_base/infrastructure/genkit/knowledge-base-zettelkasten-rules.ts`):

| Regel der Projektdoku | Wissensbasis-Agent |
| --- | --- |
| Ein Gedanke pro Notiz, 20–80 Zeilen | dto.; Längeres teilt er in mehrere Notizen eines Plans |
| Sprechender Dateiname | Der Titel benennt den Gedanken |
| Kernaussage, `Gehört zu`, `Siehe auch` | dto.; Überschriften in der Antwortsprache |
| Links über Pfade | Wiki-Links `[[Titel]]` mit exaktem Titel aus dem Tool-Ergebnis |
| Inhaltsverzeichnis in `index/` | Übersichtsnotiz: Kernaussage und gruppierte Links |
| Wissen nur an einer Stelle | erst suchen; bestehende Notiz ergänzen statt doppeln |
| Keine Waisen | Jede neue Notiz verlinkt mindestens eine bestehende; dazu ein Update, das den Rückweg ergänzt |
| „geplant“ markieren | Unbestätigtes ausdrücklich als offen kennzeichnen |

- Links nur auf Notizen, die es laut Tool-Ergebnis gibt oder die im selben
  Plan entstehen.
- **Überblick:** `listKnowledgeNoteTitles` zeigt den ganzen Zettelkasten ohne
  Inhalte: je Notiz Titel, Zahl der Links und der Rückverweise
  (`knowledgeNoteOverview`). Null Rückverweise markiert eine Waise. Der Agent
  ruft es für Fragen zur ganzen Wissensbasis und vor neuen Notizen auf, um
  Dubletten zu vermeiden und Übersichtsnotizen zu finden.
- **Lesen:** `readKnowledgeNote` liefert `links` und `backlinks`
  (berechnet mit `knowledgeLinksFrom`); der Agent folgt ihnen bei Bedarf,
  höchstens vier Notizen je Frage.
- **Antworten:** Genutzte Notizen nennt er als `[[Titel]]`. Im Panel der
  Wissensbasis öffnen diese Links die Notiz (`KnowledgeAssistantMessageBody`
  über `AssistantPanel.messageBodyBuilder`); unbekannte Titel bleiben Text.
- Die Suche läuft über alle Notizen des Teams; Titeltreffer zuerst
  (`searchKnowledgeNotes` in `knowledge_base/domain/services`).

## Siehe auch

- [Wissensbasis-Agent](./wissensbasis-agent.md) — Tools und Grenzen des Agenten
- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md) — wie `[[Ziel]]` aufgelöst wird
