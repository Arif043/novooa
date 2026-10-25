# Backend: Schichtregeln

> Domain importiert keine SDKs; Handler validieren und übersetzen, enthalten aber keine Geschäftsregeln; nur ein Composition Root verdrahtet fremde Adapter.

Gehört zu: [Architektur](../index/architektur.md)

- `domain/` importiert weder Firebase, Genkit noch Node-/HTTP-SDKs.
  `entities/` reine Typen, Value Objects, Regeln; `repositories/` nur Ports;
  `usecases/` nur Domain-Typen und Ports.
- `infrastructure/` implementiert Ports (SQLite, Genkit, Provider, Relays;
  Firestore und Functions nur für die Hintergrunddienste).
- Callable-, Scheduler- und Webhook-Handler liegen in
  `infrastructure/functions/`: Eingaben validieren, Use Cases rufen, Fehler
  übersetzen.
- Runtime-Routen sind [Fastify-Plugins](./runtime-fastify-plugins.md) in
  `infrastructure/local/local-<feature>-routes.ts` mit
  [TypeBox-Schemas](./runtime-route-schemas.md); Geschäftsregeln bleiben in
  Domain.
- Jeder öffentliche Handler protokolliert Fehler über `withExceptionLogging`
  bzw. `logException` (`shared/logging`), bevor er sie weiterwirft oder
  übersetzt.
- Ein Feature nutzt Ports anderer Features, nie deren Adapter. Nur ein
  Function-Handler als Composition Root darf fremde Adapter erzeugen.
- Rückgaben als `Result`/`ResultAsync` (`neverthrow`), Variablen
  `…OrFailure`.

**Migrationsregeln:** Öffentliche Function-Namen und Verträge bleiben; ein
Schritt verschiebt immer ein ganzes Feature; jeder Schritt mit
`npm --prefix functions run build` und Tests prüfen; Docs mit Quellpfaden im
selben Schritt anpassen.

## Siehe auch

- [Backend: Feature-First-Struktur](./backend-feature-first.md)
- [Schichtenregel](./schichtenregel.md)
