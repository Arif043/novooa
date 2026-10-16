# Agent ohne Modell testen (`/mock`)

> Im Debug-Modus beantwortet der Assistent die Eingabe `/mock` mit einem festen Plan, ohne ein Modell aufzurufen.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- `AssistantCubit` erkennt `/mock`; `MockAssistantReplies` liefert: Aufgabe
  umbenennen, drei Bausteine anlegen, Prompt befüllen.
- Damit lassen sich Plan-Ausführung und Agent-Cursor ohne LLM, Netz und Kosten
  prüfen — auch in der [UI-Vorschau](../architecture/ui-vorschau.md).
- Im Release-Build ist der Pfad inaktiv.

## Siehe auch

- [Commands und Agent-Cursor](./agent-commands-und-cursor.md)
