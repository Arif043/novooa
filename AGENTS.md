# AGENTS.md

> Einstiegspunkt für KI-Agenten und menschliche Contributors.
> Feature-spezifische Inhalte liegen in [`docs/`](./docs/README.md).

---

## 1. Was ist novooa?

**novooa** ist ein AI-Automation-System. Nutzer:innen kombinieren Bausteine
(Prompts, Bedingungen, Tool-Aufrufe, Validierungen, Freigaben) zu **Aufgaben**
(Workflows), die in der **Runtime** beim Kunden über **Genkit** ausgeführt
werden. Firebase trägt nur noch Hintergrunddienste: Lizenz, Relays und
Postfächer.

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

- Die App ist **mehrsprachig** (`easy_localization`): **Englisch ist Standard
  und Rückfall, Deutsch und Türkisch sind ergänzt (`en`, `de`, `tr`).** Beim ersten Start gilt die Gerätesprache,
  sofern unterstützt; Nutzer:innen wechseln sie unter Einstellungen. UI-Strings,
  Toasts, Tooltips, leere Zustände und Validierungsmeldungen stehen in
  `assets/translations/{en,de}.json` und werden über `LocaleKeys` (generiert)
  genutzt. Die Domänenbegriffe unten sind die **deutschen** Begriffe; die
  englischen stehen in der Tabelle.
- Domänenbegriffe (de → en: Aufgabe = Task, Baustein = Block,
  Arbeitsplan = Workplan, Zeitplan = Schedule, Aktivitäten = Activity):
  - **Aufgabe** = ein Workflow (TaskDefinition) — im deutschen UI nicht „Task".
  - **Baustein** = ein WorkflowPrimitive.
  - **Arbeitsplan** = gespeicherte / veröffentlichte Aufgaben.
  - **Zeitplan** = zeit- oder event-gesteuerte Auslöser.
  - **Aktivitäten** = Runs, Traces, Freigaben.
  - **Workflow-Ausgabewert** = fachlicher, typisierter Wert, den ein Baustein nach seiner Ausführung bereitstellt.

### Workflow-Werte und Templates

Es gibt genau einen Weg, Werte zwischen Bausteinen weiterzugeben:

- Ein Baustein erzeugt fachliche, typisierte **Workflow-Ausgabewerte**; ein Script-Baustein ausschließlich über `workflow_output("name", "typ", wert)`.
- Konfigurationen anderer Bausteine referenzieren sie über Template-Ausdrücke, zum Beispiel `{{rechnung.summe}}` oder `{{kunde}}`.
- Ein Script liest sie ausschließlich über `workflow_input("rechnung.summe")`; `{{…}}` im Script-Code wird nicht ersetzt. Variablen eines Scripts bleiben im Script.

Ein Template-Ausdruck beschreibt ausschließlich die Referenz auf einen Wert. Welche Eingabe eines Bausteins ihn verwendet, wird in dessen expliziter Konfiguration festgelegt.

---

## 2. Architektur (Überblick)

```
┌──────────────────────────┐  HTTP/WS  ┌──────────────────────────────┐
│  Flutter-Client (lib/)   │ ────────▶ │  Runtime (Docker beim Kunden) │
│  • nativ oder Web        │           │  functions/src/shared/local   │
│  • features/*            │           │  • Fastify, SQLite (Drizzle)  │
│  • Clean Architecture    │           │  • Genkit-Runner, Worker      │
└──────────────────────────┘           │  • ML-, Script-Dienst         │
                                       └──────────────┬───────────────┘
                                                      │ Lizenz, Relays
                                                      ▼
                                       ┌──────────────────────────────┐
                                       │  Firebase (Hintergrund)       │
                                       │  functions/src/index.ts       │
                                       │  Lizenz-Gateway, Wake-ups,    │
                                       │  Push-, Mail-, Agent-, Skills-│
                                       │  Relay, Microsoft-Postfächer  │
                                       └──────────────────────────────┘
```

Die Runtime liefert die Web-App selbst aus; die native App fragt nach ihrer
Adresse ([`docs/index/lokale-runtime.md`](./docs/index/lokale-runtime.md)).

Detailtiefe zu Datenmodell, Auth, Persistenz und Trigger →
[`docs/index/architektur.md`](./docs/index/architektur.md).

---

## 3. Tech-Stack

### Client (Flutter)
- Flutter / Dart SDK `^3.11.5`
- `flutter_lints: ^6.0.0`
- `firebase_core`, `firebase_messaging` — nur für optionales Push über das Relay
- Material 3, Theme siehe `lib/core/theme/syscat_theme.dart`

### Backend (`functions/`: Runtime und Firebase-Hintergrunddienste)
- Node 24, TypeScript 6
- Runtime: Fastify, SQLite über Drizzle ORM
- `genkit: ^1.37.0`, `@genkit-ai/google-genai: ^1.37.0`
- Hintergrunddienste: `firebase-functions: ^7.0.0`, `firebase-admin: ^13.6.0`
- `neverthrow: ^8.2.0` — Rückgabetypen als `Result`/`ResultAsync` (`…OrFailure`), Gegenstück zu `multiple_result` im Client
- Modelle: Sprachmodelle der Kundschaft; der Aufgabenstudio-Agent im Relay nutzt Gemini

### Kommandos

```bash
# Client
flutter pub get
flutter run -d <device>
flutter run -d chrome -t lib/main_preview.dart   # UI ohne Backend/Lizenz
flutter analyze
flutter test
(cd packages/novooa_runtime_client && flutter test)   # Client-Paket

# Backend
cd functions
npm install
npm run build          # tsc → functions/lib
npm run lint           # ESLint (typbasiert, Konfiguration: functions/eslint.config.mjs)
npm run local-runtime:serve         # Runtime ohne Docker
npm run local-runtime:docker:up     # Runtime-Stack per Docker Compose
npm run serve                       # Hintergrunddienste im Emulator
npm run deploy                      # firebase deploy --only functions
```

---

## 4. Coding-Konventionen

### Dart (Client)
- `package:flutter_lints/flutter.yaml` ist aktiv.
- Entitäten: `const` Konstruktoren, `copyWith`, Immutability.
- States: `sealed class` mit exhaustivem `switch` in der UI.
- UI-Strings nie inline: neuer Text → Schlüssel in `assets/translations/en.json`
  **und** `de.json` und `tr.json`, dann `dart run easy_localization:generate -S assets/translations -O lib/core/localization -o locale_keys.g.dart -f keys`
  und `LocaleKeys.…tr()` verwenden. `domain/` kennt kein `easy_localization`:
  dort Enums/Schlüssel liefern, übersetzt wird in `presentation/`.
- Standardnamen neuer Bausteine (Ausgabenamen, Titel) kommen über den Port
  `NodeTextDefaults`, werden beim Anlegen gespeichert und sind ASCII.
- Tests laufen mit deutschen Texten (`test/flutter_test_config.dart`); andere
  Sprache per `loadTestTranslations(Locale('en'))`.
- Dateiname = primärer Klassenname in `lower_snake_case.dart`.
- Kommentare nur für **Warum**, nicht **Was**.

### TypeScript (Functions)
- Strict, kein `any` — `z.infer<typeof schema>` für typisierte Inputs.
- Flow-Stil: `ai.defineFlow({...}, async (input) => { ... })`.
- Secrets via `defineSecret`, niemals hardcoden.
- Logging: `logger.info` Lifecycle, `logger.error` Fehler.
- ESLint: `npm --prefix functions run lint` (Flat Config mit `typescript-eslint`, typbasiert).
  `require-await` ist aus, weil Adapter asynchrone Ports ohne eigenes `await` erfüllen dürfen.

### Git
- Branch: `feat/aufgabe-<slug>`, `fix/<slug>`, `chore/<slug>`.
- Commit-Prefix: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`.
- **Vor jedem Commit:** `flutter analyze` und `npm --prefix functions run build` sauber.

---

## 5. Doc-Index

Die Docs folgen der **Zettelkasten-Methode**: atomare Notizen in
[`docs/notes/`](./docs/notes/) (flach, sprechende Namen), geordnet über
Inhaltsverzeichnisse in [`docs/index/`](./docs/index/). Regeln und Vorlage →
[`docs/README.md`](./docs/README.md). Lies erst das passende
Inhaltsverzeichnis, dann nur die Notizen, die du brauchst.

| Thema | Inhaltsverzeichnis | Inhalt |
| --- | --- | --- |
| Architektur | [`docs/index/architektur.md`](./docs/index/architektur.md) | Schichten, Backend-Struktur, Persistenz, Lokalisierung, Sicherheit, UI-Vorschau |
| Lokale Runtime | [`docs/index/lokale-runtime.md`](./docs/index/lokale-runtime.md) | Stack, Web-App, Zugriff, Transport, Datenhaltung, Ausführung, Lizenz, Relays, Schlüssel |
| Betrieb und Deployment | [`docs/index/betrieb-und-deployment.md`](./docs/index/betrieb-und-deployment.md) | Umgebungen, Microsoft-Graph-App, Deployment-CLI, Windows-Einrichtung |
| Produkt | [`docs/index/produkt.md`](./docs/index/produkt.md) | Positionierung, Kosten, Preise, Lizenzmodell |
| Aufgabe | [`docs/index/aufgabe.md`](./docs/index/aufgabe.md) | Modell, Bausteinkatalog, Aufgabenstudio, Ausführung, Executor-Outputs |
| Zeitplan | [`docs/index/zeitplan.md`](./docs/index/zeitplan.md) | Auslöser, Worker, Schleifenschutz, Kanäle, UI |
| Aktivitäten | [`docs/index/aktivitaeten.md`](./docs/index/aktivitaeten.md) | Run-Aktivitäten, Seite, Protokoll |
| Dateien | [`docs/index/dateien.md`](./docs/index/dateien.md) | Ablage, Versionen, Oberfläche, Nutzung in Aufgaben |
| Daten | [`docs/index/daten.md`](./docs/index/daten.md) | Sammlungen, Bausteine, Datenbank-Seite |
| Wissensbasis | [`docs/index/wissensbasis.md`](./docs/index/wissensbasis.md) | Notizen, Links, Graph, Anhänge |
| KI-Agent | [`docs/index/ki-agent.md`](./docs/index/ki-agent.md) | Betrieb, Multiagenten, Pläne, Cursor |
| Fähigkeiten | [`docs/index/faehigkeiten.md`](./docs/index/faehigkeiten.md) | Skills-Ordner, Import, skills.sh, Bausteine |
| Mitarbeiter | [`docs/index/mitarbeiter.md`](./docs/index/mitarbeiter.md) | Subagenten aus Rahmenbedingung und Skills |
| ML-Modelle | [`docs/index/ml-modelle.md`](./docs/index/ml-modelle.md) | Katalog, Verträge, Transformationen, ML-Dienst |
| Transformationen | [`docs/index/transformationen.md`](./docs/index/transformationen.md) | Jede Transformation des ML-Dienstes als eigene Notiz, Regeln |
| Sprachausgabe | [`docs/index/sprachausgabe.md`](./docs/index/sprachausgabe.md) | Vorlesen, Stimmen, Transkription |
| Dokumentenscanner | [`docs/index/dokumentscanner.md`](./docs/index/dokumentscanner.md) | Plattformen, Browser-Scanner, Grenzen |
| Kommunikation | [`docs/index/kommunikation.md`](./docs/index/kommunikation.md) | SendGrid, Mail-Connectoren, Twilio, Kanäle |
| Integrationen | [`docs/index/integrationen.md`](./docs/index/integrationen.md) | Plugin-Mechanik und Shopware |
| Google Drive | [`docs/index/google-drive.md`](./docs/index/google-drive.md) | Google-Konto, Scope `drive.file`, Bausteine |
| Webhooks | [`docs/index/webhooks.md`](./docs/index/webhooks.md) | Auslöser, Aufruf, Ereignis, Sicherheit |
| Verbindungen | [`docs/index/verbindungen.md`](./docs/index/verbindungen.md) | Verbindung, Anmeldung, HTTP-Anfrage |
| Import/Export | [`docs/index/import-export.md`](./docs/index/import-export.md) | Bereiche, Archivformat, Ablauf |

Designsystem (Farben, Typografie, Abstände): [`docs/DESIGN.md`](./docs/DESIGN.md).

---

## 6. Wenn du als Agent arbeitest

- **Plane zuerst.** Änderungen über mehrere Schichten oder Dateien zuerst im
  Plan-Modus skizzieren.
- **Respektiere die Schichten.** Domain kennt kein Flutter, Presentation
  kennt keine Genkit-SDKs, Infrastructure implementiert nur Domain-Interfaces.
- **Immutability ernst nehmen.** Keine „Quick-Fix"-Setter auf Entitäten.
- **Strings sind sichtbar.** Alle neuen sichtbaren Strings in `en.json`, `de.json` und `tr.json` pflegen.
- **Tests mitdenken.** Mindestens ein Cubit-Test pro neuer Mutation.
- **Keine Geheimnisse im Repo.** Auch nicht in `firebase_options.dart` — wird
  zur Laufzeit von FlutterFire generiert.
- **Docs mitziehen.** Wenn du eine API änderst, gehört die zugehörige Doc in
  denselben Commit. Insbesondere: neuer `WorkflowPrimitive` →
  Zeile in [`docs/notes/bausteinkatalog.md`](./docs/notes/bausteinkatalog.md)
  und Outputs in [`docs/notes/executor-outputs.md`](./docs/notes/executor-outputs.md).
- **Transformationen allgemein halten.** Neue Transformationen des ML-Dienstes
  beschreiben ein Verfahren, nicht ein Modell (Ausnahmen wie Piper oder
  Kokoro nur im Worst Case), kommen mit fachlichen Testfällen gegen eine
  Referenz und bekommen eine eigene Notiz `transformation-<typ>.md` im
  Inhaltsverzeichnis [Transformationen](./docs/index/transformationen.md) —
  siehe [Regeln für Transformationen](./docs/notes/regeln-fuer-transformationen.md).
- **Notizen statt Abschnitte.** Neues Wissen als atomare Notiz in
  `docs/notes/` anlegen und im passenden Inhaltsverzeichnis verlinken;
  bestehende Notizen ändern statt Wissen zu wiederholen. Nicht Umgesetztes als
  „geplant“ markieren. `test/docs/doc_links_test.dart` prüft Links, Aufbau und
  Waisen.
