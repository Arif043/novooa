# AGENTS.md

> Einstiegspunkt für KI-Agenten und menschliche Contributors.
> Feature-spezifische Inhalte liegen in [`docs/`](./docs/README.md).

---

## 1. Was ist Syscat?

**Syscat** ist ein AI-Automation-System. Nutzer:innen kombinieren Bausteine
(Prompts, Bedingungen, Tool-Aufrufe, Validierungen, Freigaben) zu **Aufgaben**
(Workflows), die über **Genkit**-Flows in der Cloud ausgeführt werden.

### Design-Philosophie

| Inspiration            | Übernehmen                                                          | Vermeiden                                              |
| ---------------------- | ------------------------------------------------------------------- | ------------------------------------------------------ |
| **Scratch**            | Visuelle Blöcke, Drag-and-Drop, sofortiges Feedback                 | Steile Lernkurve, technische Notation                  |
| **n8n**                | Graph aus Knoten + Kanten, klare Datenflüsse                        | Bloße Tabellenoptik, „Engineering-UI"                  |
| **Samsung Routines**   | Natürlichsprachliche Anlässe, „Wenn … dann …"-Erleben              | Mehrstufige Konfigurationsdialoge                      |
| **Samsung Modi**       | Ganzheitliche Szenen statt einzelner Schalter                       | Isolierte Einstellungen, die nicht zusammenpassen      |

**Ziel:** Eine Oberfläche, in der eine Automatisierung sich so anfühlt wie das
Einrichten einer Routine — „Wenn morgens der Wecker klingelt, lies meine
Termine vor und starte die Kaffeemaschine." — aber mit der Mächtigkeit von
Genkit darunter.

### Produkt-Sprache (UI)

- Die App ist **deutschsprachig**. UI-Strings, Toasts, Tooltips, leere Zustände
  und Validierungsmeldungen sind auf Deutsch.
- Domänenbegriffe:
  - **Aufgabe** = ein Workflow (TaskDefinition) — nicht „Task" im UI.
  - **Baustein** = ein WorkflowPrimitive.
  - **Arbeitsplan** = gespeicherte / veröffentlichte Aufgaben.
  - **Zeitplan** = zeit- oder event-gesteuerte Auslöser.
  - **Aktivitäten** = Runs, Traces, Freigaben.

---

## 2. Architektur (Überblick)

```
┌──────────────────────────┐         ┌──────────────────────────────┐
│  Flutter-Client (lib/)   │  HTTPS  │  Firebase Functions           │
│  • Root + Drawer + Stage │ ──────▶ │  (functions/src)             │
│  • features/*            │  Genkit │  • task-workflows.ts          │
│  • Clean Architecture    │  Flows  │  • genkit-sample.ts           │
└──────────────────────────┘         │  • @genkit-ai/google-genai    │
                                     └──────────────┬───────────────┘
                                                    ▼
                                          ┌──────────────────────┐
                                          │  Google Gemini       │
                                          │  (gemini-2.5-flash)  │
                                          └──────────────────────┘
```

Detailtiefe zu Datenmodell, Auth, Persistenz und Trigger →
[`docs/architecture.md`](./docs/architecture.md).

---

## 3. Tech-Stack

### Client (Flutter)
- Flutter / Dart SDK `^3.11.5`
- `flutter_lints: ^6.0.0`
- `firebase_core: ^4.11.0`
- Material 3, Theme siehe `lib/core/theme/syscat_theme.dart`

### Backend (Firebase Functions)
- Node 24, TypeScript 6
- `genkit: ^1.37.0`, `@genkit-ai/google-genai: ^1.37.0`
- `@genkit-ai/firebase: ^1.37.0`
- `firebase-functions: ^7.0.0`, `firebase-admin: ^13.6.0`
- Modell: `gemini-2.5-flash`

### Kommandos

```bash
# Client
flutter pub get
flutter run -d <device>
flutter analyze
flutter test

# Backend
cd functions
npm install
npm run build          # tsc → functions/lib
npm run serve          # lokal mit Emulator
npm run deploy         # firebase deploy --only functions
```

---

## 4. Coding-Konventionen

### Dart (Client)
- `package:flutter_lints/flutter.yaml` ist aktiv.
- Entitäten: `const` Konstruktoren, `copyWith`, Immutability.
- States: `sealed class` mit exhaustivem `switch` in der UI.
- UI-Strings inline auf Deutsch. Keine `.arb`/Intl-Dateien, solange mono-sprach (de).
- Dateiname = primärer Klassenname in `lower_snake_case.dart`.
- Kommentare nur für **Warum**, nicht **Was**.

### TypeScript (Functions)
- Strict, kein `any` — `z.infer<typeof schema>` für typisierte Inputs.
- Flow-Stil: `ai.defineFlow({...}, async (input) => { ... })`.
- Secrets via `defineSecret`, niemals hardcoden.
- Logging: `logger.info` Lifecycle, `logger.error` Fehler.

### Git
- Branch: `feat/aufgabe-<slug>`, `fix/<slug>`, `chore/<slug>`.
- Commit-Prefix: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`.
- **Vor jedem Commit:** `flutter analyze` und `npm --prefix functions run build` sauber.

---

## 5. Doc-Index

| Bereich               | Datei                                                              | Inhalt                                                  |
| --------------------- | ------------------------------------------------------------------ | ------------------------------------------------------- |
| Cross-cutting         | [`docs/architecture.md`](./docs/architecture.md)                   | Datenmodell, Auth, Persistenz, Trigger, Telemetrie      |
| Feature „Aufgabe"     | [`docs/features/aufgabe.md`](./docs/features/aufgabe.md)           | Task Builder — Domain, UI, Genkit-Flows, DoD            |
| Feature „Arbeitspläne" | [`docs/features/arbeitsplaene.md`](./docs/features/arbeitsplaene.md) | Stub: gespeicherte Aufgaben                          |
| Feature „Zeitplan"    | [`docs/features/zeitplan.md`](./docs/features/zeitplan.md)         | Stub: Trigger und Scheduler                             |
| Feature „Aktivitäten" | [`docs/features/aktivitaeten.md`](./docs/features/aktivitaeten.md) | Stub: Runs, Traces, Freigaben                           |

Wie du eine neue Feature-Doc anlegst → [`docs/README.md`](./docs/README.md).

---

## 6. Wenn du als Agent arbeitest

- **Plane zuerst.** Änderungen über mehrere Schichten oder Dateien zuerst im
  Plan-Modus skizzieren.
- **Respektiere die Schichten.** Domain kennt kein Flutter, Presentation
  kennt keine Genkit-SDKs, Infrastructure implementiert nur Domain-Interfaces.
- **Immutability ernst nehmen.** Keine „Quick-Fix"-Setter auf Entitäten.
- **Strings sind sichtbar.** Alle neuen sichtbaren Strings auf Deutsch.
- **Tests mitdenken.** Mindestens ein Cubit-Test pro neuer Mutation.
- **Keine Geheimnisse im Repo.** Auch nicht in `firebase_options.dart` — wird
  zur Laufzeit von FlutterFire generiert.
- **Docs mitziehen.** Wenn du eine API änderst, gehört die zugehörige Doc in
  denselben Commit. Insbesondere: neuer `WorkflowPrimitive` →
  Tabelleneintrag in [`docs/features/aufgabe.md`](./docs/features/aufgabe.md)
  § Primitives.
