---
name: novooa-dashboard
description: Entwickelt individuelle Kunden-Dashboards (Flutter, Web/Desktop/Mobil) für novooa, die parallel zum offiziellen Frontend laufen und nur Aufgaben starten, Läufe und Ergebnisse zeigen und Freigaben beantworten – ohne Aufgabenstudio, Agenten und Einstellungen. Nutzen, wenn ein Kunden-Dashboard angelegt, erweitert oder an eine neue Runtime-Version angepasst wird, oder wenn nach Anmeldung, Runtime-API, Echtzeit oder dem Paket novooa_runtime_client für ein Dashboard gefragt wird.
license: Proprietary
compatibility: Flutter mit Dart ^3.12, Lesezugriff auf das private syscat2-Repo, eine novooa-Runtime ab novooa_runtime_client 0.1.0.
metadata:
  version: "0.1.0"
  runtime-client: "0.1.0"
  owner: novooa
---

# novooa-Dashboard

Ein Kunden-Dashboard ist eine schlanke Flutter-App für **eine** Kundin oder
einen Kunden. Sie spricht dieselbe Runtime an wie das offizielle Frontend und
ersetzt es nicht.

| Gehört hinein | Gehört nicht hinein |
| --- | --- |
| Aufgaben starten (mit Eingabe) | Aufgabenstudio, Bausteine bearbeiten |
| Läufe live sehen, Ergebnis lesen | KI-Agenten, Assistent, Mitarbeiter |
| Freigaben und Formulare beantworten | Einstellungen, Benutzer, Verbindungen |
| Dateien aus Ergebnissen herunterladen | Lizenz, Ersteinrichtung, Notzugang |
| optional: Auslöser ansehen, an/aus | Auslöser anlegen oder ändern |

Lizenz, Ersteinrichtung, Notzugang und Benutzerverwaltung zeigt das Dashboard
nur als Hinweis „im offiziellen Frontend erledigen“.

## Grundregeln

1. **Anmeldung nie selbst bauen.** Verbindung, Login, Einladung, Token und
   Sitzungsende kommen aus dem privaten Paket `novooa_runtime_client`
   (`RuntimeConnectionCubit`). Siehe [Authentifizierung](references/authentifizierung.md).
2. **Nur dokumentierte Endpunkte.** Welche die Runtime anbietet und wie die
   Antworten aussehen: [Runtime-API](references/runtime-api.md). Fehlt etwas,
   wird es zuerst in syscat2 gebaut, nicht im Dashboard umgangen.
3. **Rollen respektieren.** Mitglieder dürfen Aufgaben, Läufe, Freigaben und
   Auslöser; alles Admin-Pflichtige gehört nicht ins Dashboard.
4. **Live statt Polling.** Listen hängen am Echtzeit-Kanal
   ([Echtzeit](references/echtzeit.md)).
5. **Architektur und UI wie in syscat2:** Clean Architecture je Feature,
   Cubits mit `sealed` States und den vier Zuständen, Styles nur aus dem
   Theme, Texte in `en`, `de`, `tr`. Siehe [Architektur](references/architektur.md).
6. **Kundenspezifisches nur an festen Stellen:** `lib/app/dashboard_config.dart`
   (Titel, angebotene Aufgaben), `lib/app/dashboard_theme.dart` (Farben) und
   eigene Features unter `lib/features/`. So bleiben Skill-Updates übertragbar.

## Ablauf: neues Dashboard

1. **Klären** (kurz, nicht mehr als nötig): Kundenname, Plattformen (Web,
   Desktop, Mobil), welche Aufgaben angeboten werden (IDs), ob das Modul
   „Auslöser“ gewünscht ist, Hausfarbe.
2. **Anlegen** aus der Vorlage:

   ```bash
   .claude/skills/novooa-dashboard/scripts/create_dashboard.sh "Müller GmbH" ../dashboard-mueller
   # während der Entwicklung gegen das lokale Paket:
   .claude/skills/novooa-dashboard/scripts/create_dashboard.sh "Müller GmbH" ../dashboard-mueller \
     --client-path packages/novooa_runtime_client
   ```

   Das Skript kopiert `assets/starter`, setzt Paketname, Titel und
   Paket-Tag, ergänzt die Plattformordner, schreibt `.novooa-dashboard`
   (Skill- und Paketversion) und führt `flutter pub get` aus.
3. **Anpassen:** `dashboard_config.dart` (`allowedTaskIds`), `dashboard_theme.dart`
   (`_seed`), Übersetzungen in `assets/translations/`.
4. **Erweitern** nur mit Modulen aus dem Katalog unten; jedes neue Feature
   folgt [Architektur](references/architektur.md) und bekommt Cubit-Tests.
5. **Prüfen:** `flutter analyze` ohne Hinweise, `flutter test` grün.
6. **Plattform einrichten** nach [Plattformen](references/plattformen.md)
   (Web: CORS-Freigabe der Runtime; Android/iOS: `http` im LAN; macOS:
   Keychain).
7. **Gegen eine echte Runtime testen:** anmelden, Aufgabe starten, Lauf und
   Ergebnis sehen, eine Freigabe beantworten. Die Anmeldedaten gibt die
   Kundin bzw. der Kunde selbst ein.

## Was die Vorlage schon kann

```
lib/
├── main.dart                     # EasyLocalization, DashboardApp
├── app/                          # Config, Theme, DI (DashboardDependencies), Shell, Navigation
├── connection/                   # ConnectionGate, Adresse, Anmeldung, Einladung, Hinweis Einrichtung
├── shared/                       # IDs (TaskId, RunId), Lade-/Fehler-/Leer-Ansichten
├── l10n/dashboard_keys.dart      # Übersetzungsschlüssel
└── features/
    ├── tasks/                    # Aufgaben live, Starten mit Eingabe
    └── runs/                     # Läufe live, Ergebnis, Freigabe, Formular
```

- **Anmeldung:** Adresse (Desktop/Mobil), Login, Einladungscode. Sitzungsende
  führt zurück zur Anmeldung, Abmelden vergisst Adresse und Token.
- **Aufgaben:** `GET /v1/tasks`, gefiltert über `DashboardConfig.allowedTaskIds`;
  „Starten“ fragt eine optionale Eingabe ab (`context`).
- **Läufe:** `GET /v1/task-runs`, Status-Chip, Detail mit `finalOutput`;
  wartende Läufe beantworten (Freigabe, Formular); Bild-Anfragen verweisen
  aufs offizielle Frontend. Die Zahl wartender Läufe steht an der Navigation.
- **Responsiv:** Navigation unten auf dem Handy, seitlich ab 840 px.

## Modul-Katalog

| Modul | Status in 0.1 | Wo beschrieben |
| --- | --- | --- |
| Aufgaben starten | in der Vorlage | `features/tasks` |
| Läufe und Ergebnisse | in der Vorlage | `features/runs` |
| Freigaben und Formulare | in der Vorlage | `features/runs` |
| Aktivitäten eines Laufs (Schritte, Fehler) | Rezept | [Runtime-API](references/runtime-api.md#aktivitäten) |
| Dateien herunterladen | Rezept | [Runtime-API](references/runtime-api.md#dateien) |
| Auslöser ansehen und an/aus | optional | [Modul Auslöser](references/modul-ausloeser.md) |
| Auslöser anlegen | nicht vorgesehen | offizielles Frontend |

Ein Rezept ist Code in der Referenz, den man bei Bedarf als eigenes Feature
übernimmt; die Vorlage bleibt bewusst klein.

## Grenzen der Runtime, die das Dashboard kennen muss

- `GET /v1/task-runs` und `GET /v1/activities` liefern je **höchstens 100**
  Einträge, neueste zuerst, ohne Filter oder Seiten.
- Es gibt keine Rechte pro Aufgabe: Wer angemeldet ist, sieht in der Runtime
  alle Aufgaben. `allowedTaskIds` ist Bedienkomfort, **keine
  Zugriffskontrolle**.
- `context` beim Start ist ein einzelner Text. Strukturierte Eingaben fragt
  eine Aufgabe über den Baustein „Formulareingabe“ ab (Freigabe mit Formular).
- Über `http` laufen Token und Inhalte im Klartext: nur im vertrauenswürdigen
  LAN, sonst `https` über einen Reverse Proxy.

## Versionierung

- Der Skill folgt SemVer (`metadata.version`); Änderungen stehen in
  [CHANGELOG.md](CHANGELOG.md). `metadata.runtime-client` nennt die Version
  von `novooa_runtime_client`, für die Vorlage und Referenzen geschrieben sind.
- Jedes Dashboard hält in `.novooa-dashboard` fest, mit welcher Skill- und
  Paketversion es erzeugt wurde.
- Ein Dashboard aktualisieren: CHANGELOG ab der eigenen Version lesen,
  `ref` in `pubspec.yaml` auf den neuen Tag `novooa-runtime-client-v<x.y.z>`
  heben, Änderungen der Vorlage gezielt übernehmen, `.novooa-dashboard`
  anpassen, testen.
- Wer Vorlage, Referenzen oder Skript ändert, hebt die Version und ergänzt
  den CHANGELOG im selben Commit.

## Checkliste vor der Übergabe

- [ ] Nur Module aus dem Katalog; nichts aus Studio, Agenten, Einstellungen
- [ ] Anmeldung ausschließlich über `novooa_runtime_client`
- [ ] Jede Liste mit Laden, Fehler (mit „Erneut versuchen“), Leer (mit Aktion), Erfolg
- [ ] Keine festen Farben, Schriftgrößen oder Abstände außerhalb des Themes
- [ ] Alle Texte in `en`, `de`, `tr`; Schlüssel in `dashboard_keys.dart`
- [ ] Touch-Ziele ≥ 48 px, Icons mit `tooltip` oder `semanticLabel`
- [ ] `flutter analyze` ohne Hinweise, `flutter test` grün, Dateien ≤ 200 Zeilen
- [ ] Plattform-Einstellungen nach [Plattformen](references/plattformen.md)
- [ ] `.novooa-dashboard` stimmt mit `pubspec.yaml` überein
