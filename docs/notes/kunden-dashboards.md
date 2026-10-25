# Kunden-Dashboards

> Für einzelne Kunden entstehen eigene Flutter-Dashboards, die neben dem offiziellen Frontend laufen und nur Aufgaben starten, Läufe zeigen und Freigaben beantworten.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Umfang:** Aufgaben starten, Läufe und Ergebnisse live, Freigaben und
  Formulare; optional Auslöser an/aus. Kein Aufgabenstudio, keine Agenten,
  keine Einstellungen, keine Ersteinrichtung oder Lizenz.
- **Anmeldung** wie im offiziellen Frontend über das
  [Client-Paket](./runtime-client-paket.md); Konten legt ein Admin im
  offiziellen Frontend an, die Person löst im Dashboard ihren Einladungscode ein.
- **Bauanleitung, Referenzen und Vorlage** stehen im Skill
  `.claude/skills/novooa-dashboard/` (Standard agentskills.io, versioniert
  über `metadata.version` und `CHANGELOG.md`). Ein Dashboard entsteht mit
  `scripts/create_dashboard.sh` und liegt in einem eigenen Repo.
- **Web:** Das Dashboard läuft auf einer eigenen Herkunft; die Runtime braucht
  dafür `LOCAL_RUNTIME_ALLOWED_ORIGINS` und das Dashboard
  `--dart-define=WORKSPACE_API_URL=…`.
- **Grenze:** Die Runtime kennt keine Rechte pro Aufgabe; die Auswahl der
  angezeigten Aufgaben im Dashboard ist keine Zugriffskontrolle.

## Siehe auch

- [Die Runtime liefert die Web-App aus](./runtime-liefert-web-app.md)
- [Runtime-Sitzungen](./runtime-sitzungen.md)
