# Agentenmodell über Remote Config

> Das Modell der Cloud-Agenten steht im Remote-Config-Parameter `assistant_model`; eine Änderung wirkt spätestens nach fünf Minuten, ohne Deploy.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- Wert: Google-Modellname (Gemini API), z. B. `gemini-3.1-flash-lite`
  (Standard im Code). Keine Auswahl durch Nutzer:innen, keine pro Team.
- Gelesen über `RemoteConfigAssistantModel`, gecacht fünf Minuten
  (`CachedAssistantModelSettings`) von `runTaskBuilderAssistant` und
  `askKnowledgeBaseAssistant`. Gilt auch für alle Subagenten.
- Leer, fehlend oder ungültig geschrieben (erlaubt: Kleinbuchstaben, Ziffern,
  `.`, `-`, `_`) → Standardmodell aus `ai-models.ts` (`GOOGLE_TEXT_MODEL`).
- Ein gültig geschriebener, aber unbekannter Name wird nicht vorab geprüft.
  Abgeschaltete Google-Modelle führen zu 404 bei jeder Anfrage — der Name muss
  aktuell verfügbar sein.
- Remote Config nicht erreichbar: Der letzte Wert bleibt (anfangs keiner);
  nach 30 Sekunden neuer Versuch.
- Secret: `GEMINI_API_KEY`.

## Siehe auch

- [Wo die KI-Agenten laufen](./ki-agenten-betriebsorte.md)
- [Modellprovider für Prompt-Bausteine](./modellprovider-prompt.md)
