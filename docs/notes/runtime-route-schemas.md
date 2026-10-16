# Route-Schemas mit TypeBox

> Jede Route deklariert `params`, `querystring`, `body` und `response` als TypeBox-Schema; nicht deklarierte Felder erscheinen nie in einer Antwort.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Typen über `@fastify/type-provider-typebox`; Fastify validiert mit Ajv und
  serialisiert mit fast-json-stringify. Deshalb kann z. B. kein API-Key
  versehentlich in einer Antwort landen.
- Pfad-, Query- und Header-Werte werden in den Schema-Typ umgewandelt,
  JSON-Bodies bewusst nicht (`local-runtime-validation.ts`):
  `{"blockModelId": 42}` ist ein Fehler, keine Zeichenkette.
- Schema-Verletzung: `400 {error: "Ungültige Anfrage.", code:
  "invalid_request", field}`. Fachliche Prüfungen (gültiger Zeitplan,
  Anbieter-URL) liefern eigene Meldungen.
- Task-Runs behalten den mit der Cloud geteilten Vertrag
  `{failure: {code, message}}` (`attachValidation`).

## Siehe auch

- [Fastify-Plugins der Runtime](./runtime-fastify-plugins.md)
