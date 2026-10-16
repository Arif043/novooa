# Sprachmodell-Anbieter

> Eine Verbindung pro Anbieter lädt dessen gesamten Modellkatalog; API-Keys verlassen den verschlüsselten Secret Store nie.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Anbieter in den Einstellungen: Google AI, xAI (Grok), Mistral AI, OpenRouter,
Abacus.AI (RouteLLM), Hugging Face, ElevenLabs (nur Sprachausgabe), Ollama
(lokal) und frei konfigurierbare OpenAI-kompatible Anbieter.

- Verbinden: `POST /v1/language-model-connections`; die Runtime speichert alle
  Textmodelle unter dieser Verbindung. Auswahl im Aufgabenstudio über
  `GET /v1/language-models`.
- ElevenLabs: Stimmen über `GET /v1/language-models/:id/voices`.
- xAI, Mistral, OpenRouter, Abacus.AI, Hugging Face: feste HTTPS-Endpunkte,
  nicht überschreibbar.
  - Abacus.AI: `https://routellm.abacus.ai/v1`, dazu Pseudo-Modell
    `route-llm` für automatische Modellwahl. Enterprise-Arbeitsbereiche
    (`https://<arbeitsbereich>.abacus.ai/v1`) über den generischen Anbieter.
  - Hugging Face: `https://router.huggingface.co/v1`; Modelle und Fähigkeiten
    (Werkzeuge, strukturierte Ausgabe, Bildeingabe) aus `GET /v1/models`.
  - Beide sprechen das OpenAI-Protokoll, erscheinen aber bewusst als eigene
    Anbieter.
- Ollama: ohne Eingabe `http://host.docker.internal:11434/v1`, als lokales
  Genkit-Modell; Transport über die native `/api/chat`-API, JSON-Schemas als
  Ollama-`format`. Intern ein nicht geheimer Platzhalter-Key.
- Generisch OpenAI-kompatibel: extern HTTPS-URL plus API-Key; lokal
  `http://host.docker.internal:<port>/v1`.

## Siehe auch

- [Feldverschlüsselung mit Envelopes](./feldverschluesselung-envelope.md)
- [Sprachmodelle ohne eigene Team-ID (0010)](./sqlite-sprachmodelle-normalisiert.md)
- [Aufgabe: Executoren](../features/aufgabe-executoren.md)
