# AGENTS.md

> Einstiegspunkt für KI-Agenten und menschliche Contributors.
> Feature-spezifische Inhalte liegen in [`docs/`](./docs/README.md).

---

## 1. Was ist novooa?

**novooa** ist ein AI-Automation-System. Nutzer:innen kombinieren Bausteine
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
  - **Variable** = benannter Wert, den ein Script-Baustein definiert und der für nachfolgende Bausteine verfügbar ist.

### Workflow-Werte und Templates

Workflow-Ausgabewerte und Variablen sind unterschiedliche Domänenkonzepte:

- Ein Baustein erzeugt fachliche, typisierte **Workflow-Ausgabewerte**.
- Ein Script-Baustein kann benannte **Variablen** definieren.
- Beide können über Template-Ausdrücke referenziert und in Konfigurationen eingebunden werden, zum Beispiel `{{rechnung.summe}}` oder `{{kunde}}`.

Ein Template-Ausdruck beschreibt ausschließlich die Referenz auf einen Wert. Welche Eingabe eines Bausteins ihn verwendet, wird in dessen expliziter Konfiguration festgelegt.

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
- `neverthrow: ^8.2.0` — Rückgabetypen als `Result`/`ResultAsync` (`…OrFailure`), Gegenstück zu `multiple_result` im Client
- Modell: `gemini-2.5-flash`

### Kommandos

```bash
# Client
flutter pub get
flutter run -d <device>
flutter run -d chrome -t lib/main_preview.dart   # UI ohne Backend/Lizenz
flutter analyze
flutter test

# Backend
cd functions
npm install
npm run build          # tsc → functions/lib
npm run lint           # ESLint (typbasiert, Konfiguration: functions/eslint.config.mjs)
npm run serve          # lokal mit Emulator
npm run deploy         # firebase deploy --only functions
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

Die Docs werden featureweise auf die **Zettelkasten-Methode** umgestellt:
atomare Notizen in [`docs/notes/`](./docs/notes/) (flach, sprechende Namen),
geordnet über Inhaltsverzeichnisse in [`docs/index/`](./docs/index/). Regeln →
[`docs/README.md`](./docs/README.md). Noch nicht umgestellte Features stehen
weiter als Deep-Dive unter `docs/features/`.

| Bereich               | Datei                                                              | Inhalt                                                  |
| --------------------- | ------------------------------------------------------------------ | ------------------------------------------------------- |
| Cross-cutting         | [`docs/architecture.md`](./docs/architecture.md)                   | Datenmodell, Auth, Persistenz, Trigger, Telemetrie      |
| UI-Vorschau           | [`docs/architecture/ui-vorschau.md`](./docs/architecture/ui-vorschau.md) | UI ohne Backend/Lizenz starten (`lib/main_preview.dart`, VS-Code-Profil) |
| Lokale Runtime        | [`docs/index/lokale-runtime.md`](./docs/index/lokale-runtime.md)   | Inhaltsverzeichnis: Stack, Zugriff, Datenhaltung, Ausführung, Lizenz, Relays, Schlüssel |
| SQLite-Normalisierung | [`docs/architecture/sqlite-normalisierung.md`](./docs/architecture/sqlite-normalisierung.md) | Tabellenprüfung und offene Abhängigkeiten |
| Betriebsvarianten     | [`docs/architecture/betriebsvarianten.md`](./docs/architecture/betriebsvarianten.md) | Clients × Cloud/Standalone: Blocker und Umsetzungsschritte |
| Feature „Aufgabe"     | [`docs/index/aufgabe.md`](./docs/index/aufgabe.md)                 | Inhaltsverzeichnis: Modell, Aufgabenstudio, Ausführung, Bausteine, Arbeitspläne |
| Feature „Zeitplan"    | [`docs/index/zeitplan.md`](./docs/index/zeitplan.md)               | Inhaltsverzeichnis: Auslöser, Worker, Schleifenschutz, UI |
| Feature „Kommunikation" | [`docs/features/kommunikation.md`](./docs/features/kommunikation.md) | System-E-Mail und Kundenpostfach-Connectoren          |
| Feature „Aktivitäten" | [`docs/features/aktivitaeten.md`](./docs/features/aktivitaeten.md) | Stub: Runs, Traces, Freigaben                           |
| Feature „Dateien"     | [`docs/index/dateien.md`](./docs/index/dateien.md)                 | Inhaltsverzeichnis: Ablage, Versionen, Oberfläche, Nutzung in Aufgaben |
| Feature „Daten"       | [`docs/features/daten.md`](./docs/features/daten.md)               | Dokumentorientierte Daten und lokale Speicherung         |
| Feature „Wissensbasis" | [`docs/features/wissensbasis.md`](./docs/features/wissensbasis.md) | Markdown-Zettelkasten für Node-Anhänge                  |
| Feature „Fähigkeiten" | [`docs/features/skills.md`](./docs/features/skills.md)             | SKILL.md-Fähigkeiten: Skills-Ordner, Import, skills.sh      |
| Feature „Integrationen" | [`docs/features/integrationen.md`](./docs/features/integrationen.md) | Plugins für externe Systeme: Ablage, Vertrag, Importregel, Bausteine |
| Feature „Shopware" | [`docs/features/shopware.md`](./docs/features/shopware.md) | Shopware-6-Plugin: Einrichtung, Aktionen, Ausgabemodell |
| Feature „Webhooks"   | [`docs/features/webhooks.md`](./docs/features/webhooks.md)         | Eingehende Aufrufe externer Systeme: Auslöser, Adresse, Signatur, Baustein „Webhook-Ereignis“ |
| Feature „Verbindungen" | [`docs/features/verbindungen.md`](./docs/features/verbindungen.md) | Zugänge zu externen HTTP-APIs und der Baustein „HTTP-Anfrage“ |
| Feature „Mitarbeiter" | [`docs/features/mitarbeiter.md`](./docs/features/mitarbeiter.md)   | Subagents: Rahmenbedingung (System-Prompt) + Skills     |
| Feature „KI-Agent"    | [`docs/index/ki-agent.md`](./docs/index/ki-agent.md)         | Inhaltsverzeichnis: Betrieb, Multiagenten, Pläne, Cursor |
| Feature „ML-Modelle"  | [`docs/index/ml-modelle.md`](./docs/index/ml-modelle.md)           | Inhaltsverzeichnis: Katalog, Verträge, Transformationen, ML-Dienst |
| Feature „Dokumentenscanner" | [`docs/features/dokumentscanner.md`](./docs/features/dokumentscanner.md) | Bild anfordern als Scan: Android/iOS nativ, Web mit eigener Erkennung |
| Feature „Sprachausgabe" | [`docs/features/sprachausgabe.md`](./docs/features/sprachausgabe.md) | Text vorlesen über Sprachmodelle, Stimmenliste        |
| Feature „Import/Export" | [`docs/features/import-export.md`](./docs/features/import-export.md) | Standalone: Export/Import von Dateien, Daten, Wissensbasis, Aufgaben |

Wie du eine neue Feature-Doc anlegst → [`docs/README.md`](./docs/README.md).

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
- **Notizen statt Abschnitte.** In umgestellten Features (mit Eintrag in
  `docs/index/`) neues Wissen als atomare Notiz in `docs/notes/` anlegen und im
  passenden Inhaltsverzeichnis verlinken; bestehende Notizen ändern statt
  Wissen zu wiederholen. Lies erst das Inhaltsverzeichnis, dann nur die
  benötigten Notizen. `test/docs/doc_links_test.dart` prüft Links und Waisen.
