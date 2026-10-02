# Feature: Fähigkeiten (Skills)

Verwandt: [`aufgabe.md`](./aufgabe.md) · [`mitarbeiter.md`](./mitarbeiter.md) · [`wissensbasis.md`](./wissensbasis.md)

## Zweck

Fähigkeiten (Skills) sind wiederverwendbare Anweisungen mit Progressive Disclosure nach dem offenen Standard
[agentskills.io](https://agentskills.io/specification). Ein Skill ist ein **Ordner** mit einer `SKILL.md`
(YAML-Kopf mit `name` und `description`, danach Markdown) und optional `scripts/`, `references/`, `assets/`.
Skills sind kein eigener Baustein, sondern werden — wie die Wissensbasis — an unterstützte Bausteine
(Prompt, Iterative Verfeinerung) gehängt.

**Verfügbarkeit:** Standalone (lokale Runtime). In der Cloud ist das Feature aus (`WorkspaceCapabilities.skills`),
bis dort ein Speicher existiert.

## Der Skills-Ordner ist die Quelle der Wahrheit

Jeder Nutzer hat einen **Skills-Basisordner**; jeder Skill ist ein Unterordner:

```text
<skills-ordner>/
├── pdf-verarbeitung/
│   ├── SKILL.md
│   ├── references/REFERENCE.md
│   └── scripts/extract.py
└── code-review/
    └── SKILL.md
```

Es gibt keine Datenbanktabelle. Name, Beschreibung, Lizenz und Kompatibilität liest die App aus dem Kopf der
`SKILL.md`; **Kennung ist der Ordnername**. Ordner, die der Nutzer von Hand hineinlegt, sind sofort Skills
(„Neu einlesen“ in der App genügt). Ordner ohne `SKILL.md` und versteckte Ordner (`.…`) werden ignoriert; Skills mit
Problemen (fehlende Beschreibung, abweichender Name im Kopf) erscheinen mit Warnung statt zu verschwinden.

Pfad: `NOVOOA_SKILLS_DIR`, sonst `<Runtime-Verzeichnis>/skills`. Mit `docker-compose.local.yaml` ist es ein
Bind-Mount auf dem Host (`${NOVOOA_SKILLS_DIR:-./novooa-skills}`); der Dienst `skills-init` übergibt den Ordner
dem Benutzer der Runtime, damit Importe schreiben können. Die App zeigt den Pfad oben auf der Seite
**Fähigkeiten**.

## Standard (agentskills.io)

| Feld            | Regel                                                                                     |
| --------------- | ----------------------------------------------------------------------------------------- |
| `name`          | 1–64 Zeichen, `a-z`, `0-9`, Bindestriche; nicht am Rand, nicht doppelt; == Ordnername     |
| `description`   | Pflicht, 1–1024 Zeichen: was der Skill tut und wann er einzusetzen ist                    |
| `license`       | optional                                                                                  |
| `compatibility` | optional, ≤ 500 Zeichen                                                                   |
| `metadata`      | optional, String-Map                                                                      |
| `allowed-tools` | optional, experimentell — wird gelesen, aber nicht ausgewertet                            |

Reale Skills halten das nicht immer ein. Beim **Import** wird deshalb korrigiert und gewarnt: Ein fehlender oder
ungültiger `name` wird aus dem Ordnernamen abgeleitet („Next.js Development“ → `next-js-development`), und der Kopf
der gespeicherten `SKILL.md` bekommt den korrigierten Namen. Abgelehnt wird nur bei fehlender `SKILL.md` oder
`description` sowie bei verletzten Grenzen (höchstens 200 Dateien und 10 MB je Skill, keine Pfade mit `..`).
Dateien wie `.git/`, `node_modules/` und `__MACOSX/` werden nicht übernommen.

## Import

In der App: **Fähigkeiten → Importieren** (Sheet). Quellen:

| Quelle      | Verhalten                                                                                                    |
| ----------- | ------------------------------------------------------------------------------------------------------------ |
| **GitHub**  | `https://github.com/o/r`, `…/tree/<branch>/<pfad>` oder `o/r`; lädt das Repository als ZIP von `codeload.github.com` (zählt nicht gegen das REST-Limit von 60/h), höchstens 25 MB, nur öffentliche Repositories. Findet auch mehrere Skills je Repository. |
| **ZIP**     | Archiv mit einem oder mehreren Skill-Ordnern; ein gemeinsamer Wurzelordner wird abgeschnitten; höchstens 25 MB, entpackt höchstens 100 MB (Zip-Bomben-Schutz). |
| **Ordner**  | nur Desktop: Ordner eines Skills oder ein Ordner mit mehreren Skills; höchstens 10 MB / 2000 Dateien.         |
| **Katalog** | Suche und Bestenliste von skills.sh (siehe unten).                                                           |

Ablauf in zwei Schritten, damit nichts ungefragt gespeichert wird: **Vorschau** (`POST /v1/skills/imports…`) liest
die Quelle und listet die gefundenen Skills mit Hinweisen und abgelehnten Ordnern; **Übernehmen**
(`POST …/commit`) speichert die Auswahl. Ist ein Name vergeben, wird `-2`, `-3` … angehängt. Die Vorschau liegt
15 Minuten im Speicher (höchstens 10 gleichzeitig).

### skills.sh-Katalog

Adapter für die [skills.sh-API](https://www.skills.sh/docs/api) (`GET /skills`, `/skills/search`, `/skills/curated`,
`/skills/{quelle}/{skill}`, `/skills/audit/…`). Ein Katalog-Skill wird über den Detail-Endpunkt importiert, der alle
Dateien als Text liefert — GitHub wird nicht gebraucht (Binärdateien fehlen; die Vorschau warnt davor). Bei Katalog-
Skills zeigt die Vorschau die **Sicherheitsprüfungen** der Partner (Socket, Snyk, …).

**Zugang:** Die API verlangt für jeden Aufruf ein Vercel-OIDC-Token. Deshalb läuft der Katalog über einen eigenen
Proxy ([`relay/skills-sh-proxy`](../../relay/skills-sh-proxy/README.md)), der das Token einsetzt. Konfiguration der
Runtime:

| Variable             | Bedeutung                                                                          |
| -------------------- | ---------------------------------------------------------------------------------- |
| `SKILLS_SH_BASE_URL` | Adresse des Proxys, z. B. `https://<projekt>.vercel.app/api/v1`                    |
| `SKILLS_SH_TOKEN`    | Zugangsschlüssel des Proxys; **ohne** `SKILLS_SH_BASE_URL` direkt ein OIDC-Token gegen `https://skills.sh/api/v1` |

Ohne beides ist der Katalog-Tab deaktiviert („nicht eingerichtet“); GitHub/ZIP/Ordner funktionieren trotzdem.

**Rate-Limits (600 Anfragen/Minute je Projekt):** Der Client (`SkillsShClient`) hält sie ein, statt sie auszureizen:

- merkt sich `X-RateLimit-Remaining/Reset`; ist das Kontingent erschöpft, wartet er bis zum Reset (höchstens 30 s)
  oder meldet „Zu viele Anfragen … in N Sekunden“ (HTTP 429 mit `Retry-After` an die App);
- befolgt `Retry-After` bei 429 (höchstens 2 Wiederholungen), wiederholt 503 mit Backoff (1 s, 2 s);
- hält Antworten nach `Cache-Control` vor (Standard 60 s Suche/Liste, 300 s Detail) und fasst gleiche gleichzeitige
  Anfragen zusammen;
- ein gemeinsamer Client für Suche, Bestenliste und Import — Limit und Cache gelten also gemeinsam.

Die App entprellt die Suche (400 ms) und sendet erst ab zwei Zeichen.

## Node-Anhänge

`PromptNodeConfig` und `IterativeRefinementNodeConfig` speichern eine Liste `skillAttachments`. Ein Anhang
verweist nur auf den Ordnernamen:

```json
{"name": "pdf-verarbeitung", "description": "Verarbeitet PDFs …"}
```

`description` dient nur der Anzeige. Mitarbeiter ([`mitarbeiter.md`](./mitarbeiter.md)) tragen ihre `defaultSkills`
im selben Format; Duplikate werden nach `name` zusammengeführt, Skills des Knotens gewinnen.

## Ausführung im TaskRun

Bevor ein Baustein das Modell ruft, kopiert
[`skill-workspace.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/skill-workspace.ts)
die **angehängten** Skill-Ordner (nicht den ganzen Skills-Ordner) nach `<node-workspace>/skills/<name>/`. Dabei
bekommt die `SKILL.md` im Workspace den Ordnernamen als `name` und eine einzeilige `description`: Die Genkit-Middleware
liest den Kopf mit einer Einzeilen-Suche und kommt mit gefalteten Beschreibungen (`description: >`) nicht zurecht. Die
Originale im Skills-Ordner bleiben unverändert.

[`node-attachment-genkit.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-genkit.ts)
hängt `skills({skillPaths: [<skillsDir>]})` aus `@genkit-ai/middleware` an:

1. Ein System-Prompt-Fragment listet die verfügbaren Skills (Name + Beschreibung).
2. Das Werkzeug `use_skill` liefert die `SKILL.md` — Progressive Disclosure.
3. Weitere Dateien (`references/…`) liest das Modell über die `filesystem`-Middleware, die auf demselben Workspace
   arbeitet.

Fehlt ein angehängter Skill (Ordner gelöscht), bricht der Baustein mit „Der Skill „x“ wurde nicht gefunden“ ab; der
Fehler steht in der Aktivität. Der Dienst `skillContentReader` gehört zur `TaskGraphRuntime` (nicht zu
`TaskRunServices`), weil nur der Runner ihn nutzt.

## Sicherheit

Skills sind **Anweisungen von Dritten** und damit ein Weg für Prompt-Injection. Deshalb: Vorschau vor dem Speichern
mit Quelle, Dateianzahl und Warnungen; bei Katalog-Skills die Partner-Audits; Skripte in `scripts/` werden
gespeichert, aber **nie ausgeführt** — das Modell hat nur lesende Werkzeuge (`use_skill`, `list_files`,
`read_file`). Pfade werden gegen `..`, absolute Pfade und Zip-Slip geprüft, Archive gegen Zip-Bomben.

## HTTP-API (lokale Runtime)

| Route                                         | Zweck                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------- |
| `GET /v1/skills`                              | liest den Skills-Ordner                                                   |
| `GET /v1/skills/location`                     | Pfad des Skills-Ordners                                                   |
| `DELETE /v1/skills/:name`                     | löscht den Skill-Ordner                                                   |
| `POST /v1/skills/imports`                     | Vorschau aus `{github:{url}}`, `{folder:{name,files}}` oder `{skillsSh:{id}}` |
| `POST /v1/skills/imports/archive?name=`       | Vorschau aus einem ZIP (`application/zip`)                                |
| `POST /v1/skills/imports/:importId/commit`    | übernimmt `{names:[…]}`                                                   |
| `GET /v1/skills/catalog/status`               | ist ein Katalog eingerichtet?                                             |
| `GET /v1/skills/catalog/search?q=`            | Suche (≥ 2 Zeichen)                                                       |
| `GET /v1/skills/catalog/browse?view=&page=`   | Bestenliste (`all-time`, `trending`, `hot`)                               |
| `GET /v1/skills/catalog/audits?id=`           | Sicherheitsprüfungen                                                      |

Änderungen werden über das Realtime-Thema `skills` gemeldet.

## UI

Route `/skills`, Drawer-Label **Fähigkeiten** (nur in Standalone). Die Seite zeigt den Skills-Ordner (kopierbar,
„Neu einlesen“), die gefundenen Skills mit Warnungen, Löschen und den Import-Sheet. Im Inspector von „Prompt“ und
„Iterative Verfeinerung“ erscheint die Sektion „Fähigkeiten“ mit dem Auswahlmuster der Wissensbasis.

## Offen

- Cloud-Variante (Firebase Storage statt Ordner) und Migration vorhandener Cloud-Skills.
- Updates importierter Skills (Vergleich mit dem `hash` von skills.sh) und Herkunftsangabe je Skill.
- Mitarbeiter: Standard-Skills sind auf `name` umgestellt; die Mitarbeiter-Oberfläche folgt im nächsten Schritt.

## Definition of Done

- [x] Skills lassen sich per GitHub, ZIP und Ordner importieren; der Katalog (skills.sh) ist angebunden.
- [x] Skills liegen als Ordner im Skills-Ordner; von Hand hinzugefügte Ordner werden erkannt.
- [x] Angehängte Skills erscheinen als Ordner im Node-Workspace; die Genkit-Skill-Middleware bietet sie unter ihrem
      Ordnernamen an.
- [x] Rate-Limits von skills.sh werden eingehalten (Header, `Retry-After`, Cache, Backoff).
- [x] `flutter analyze` und `npm --prefix functions run build` sind sauber.
