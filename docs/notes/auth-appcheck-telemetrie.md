# Auth, App Check und Telemetrie

> Cloud-Auth ist Firebase Auth; App Check und Telemetrie sind vorbereitet, aber noch nicht aktiviert.

Gehört zu: [Architektur](../index/architektur.md)

- **Auth:** Firebase Auth. `onCallGenkit` unterstützt `authPolicy`
  (`hasClaim`, `isSignedIn`).
- **Passwort ändern (Cloud):** `SetNewPassword` über den Port
  `PasswordRepository`; der Firebase-Adapter nutzt `User.updatePassword`.
  Meldet Firebase `requires-recent-login`, zeigt die App einen Hinweis auf
  erneute Anmeldung. Der Cubit hält keine Passwörter im State und verhindert
  paralleles Speichern. Standalone: [Passwort ändern](./passwort-aendern.md).
- **App Check (geplant):** `enforceAppCheck: true`, sobald das erste Feature
  produktiv geht.
- **Telemetrie (geplant):** `enableFirebaseTelemetry()` aus
  `@genkit-ai/firebase` (Traces und Metrics in Cloud Observability); im Client
  `firebase_crashlytics`.

## Siehe auch

- [Genkit-Flow-Konventionen](./genkit-flow-konventionen.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
