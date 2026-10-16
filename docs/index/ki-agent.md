# KI-Agent

> Der In-App-Agent hilft beim Bauen von Aufgaben und beim Pflegen der Wissensbasis; er schlägt Änderungen nur vor, die Nutzer:innen ausdrücklich ausführen.

## Betrieb

- [Wo die KI-Agenten laufen](../notes/ki-agenten-betriebsorte.md)
- [Agentenmodell über Remote Config](../notes/agent-modell-remote-config.md)
- [Relay des Aufgabenstudio-Agenten](../notes/aufgabenstudio-agent-relay.md)
- [Antwortsprache des Agenten](../notes/agent-antwortsprache.md)

## Aufbau

- [Architektur des Assistenten](../notes/assistent-architektur.md)
- [Multiagenten-Architektur des Aufgabenstudios](../notes/multiagenten-aufgabenstudio.md)
- [Wissensbasis-Agent](../notes/wissensbasis-agent.md)
- [URL Context und Seitenlinks](../notes/url-context-und-seitenlinks.md)

## Änderungen ausführen

- [Änderungspläne des Agenten](../notes/agent-aenderungsplaene.md)
- [Commands und Agent-Cursor](../notes/agent-commands-und-cursor.md)
- [Agent ohne Modell testen (`/mock`)](../notes/agent-mock.md)

## Offene Punkte

- Interne Wissensbasis später aus Markdown-Assets oder vom Backend laden?
- Antworten und Verläufe pro Team speichern?
- System-Prompts sind noch deutsch.
- Weitere Commands: `configureNode` für bestehende Bausteine, `connectNodes`,
  `removeNode`, `updateTaskObjective`.

## Verwandt

- [Aufgabe](./aufgabe.md)
- [ML-Modelle](./ml-modelle.md) — Modellsuche des Agenten
- [Wissensbasis](./wissensbasis.md)
- [Lokale Runtime](./lokale-runtime.md)
