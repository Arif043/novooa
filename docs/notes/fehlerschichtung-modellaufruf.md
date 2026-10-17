# Fehlerschichtung eines Modellaufrufs

> Framework-Fehler werden in der Infrastructure zu unseren Exceptions übersetzt; die Komponente, die den Domain-Port implementiert, bildet sie auf eine `LanguageModelFailure` mit stabilem Code ab.

Gehört zu: [Architektur](../index/architektur.md)

1. **Unsere Exceptions** (`language_models/infrastructure/errors/language-model-errors.ts`):
   `ModelOutputSchemaError`, `ModelResponseTruncatedError`,
   `ModelEmptyResponseError`, `ModelProviderUnavailableError`,
   `ModelRequestRejectedError`, `ModelTimeoutError`,
   `ModelCapabilityMissingError`; Basis `LanguageModelError` mit
   `originalError`.
2. **Adapter werfen sie direkt**, z. B. der Ollama-Adapter bei
   `done_reason: length` oder leerer Antwort — noch bevor Genkit das
   Ausgabeschema prüft, damit die echte Ursache ankommt.
3. **Übersetzen:** Jeder Genkit-Aufruf läuft in `withTranslatedGenkitErrors`
   (`genkit-error-translator.ts`): `GenkitError` (Schemafehler, Statusnamen),
   HTTP-Status der Anbieter-SDKs, Zeitüberschreitung und Netzfehler werden zu
   unseren Exceptions; Unbekanntes bleibt unverändert.
   Vorher wiederholt `languageModelRetry` (Genkit-Middleware in
   `aiTurnMiddleware`) nur vorübergehende Fehler: nicht erreichbarer Anbieter
   und `GenkitError` mit `UNAVAILABLE`/`RESOURCE_EXHAUSTED`/`ABORTED`/
   `INTERNAL`. Genkits eigenes `retry` wiederholte jeden anderen Fehler, auch
   abgeschnittene Antworten und Zeitüberschreitungen; ein langsames lokales
   Modell lief so viermal. Ollama-Aufrufe haben 10 Minuten Zeit.
4. **Abbilden:** `GenkitPromptExecutor` implementiert den Domain-Port
   `PromptExecutor` und wandelt an seiner Grenze per
   `languageModelFailureFrom` in `err(LanguageModelFailure)` um; alles
   Unbekannte wird `unknown`.
5. **Weitergeben:** Der Node-Executor verpackt die Failure in
   `NodeFailedError`; der Runner übernimmt den Code in
   `FailedNode.failureCode` ([Fehlgeschlagene Bausteine](./baustein-fehler-aktivitaeten.md)).
6. **Anzeigen:** Der Client (`ActivityFailureCode`) übersetzt bekannte Codes
   (en/de/tr); der deutsche Text der Runtime bleibt als technisches Detail.

Codes: `outputSchemaViolated`, `responseTruncated`, `emptyResponse`,
`providerUnavailable`, `requestRejected`, `timedOut`, `capabilityMissing`,
`unknown`.

## Siehe auch

- [Prompt-Executor](./prompt-executor.md)
- [Generierungsoptionen](./generierungsoptionen.md)
- [Backend: Schichtregeln](./backend-schichtregeln.md)
