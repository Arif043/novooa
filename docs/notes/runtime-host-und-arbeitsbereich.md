# Host und Arbeitsbereich der Runtime

> Die Runtime trennt prozessweite Infrastruktur (`LocalRuntimeHost`: Datenbank, Wurzelverzeichnis, Feldverschlüsselung) von der Identität der aktiven Lizenz (`LocalRuntimeWorkspace`: Team, Teamname, Nutzer).

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Host** (`shared/local/local-runtime-host.ts`): entsteht einmal im Entrypoint,
  bevor eine Lizenz aktiv ist — Prozesssperre, Datenbank und Schlüssel brauchen
  `runtimeRoot` schon vorher. Er bleibt bis zum Herunterfahren unverändert.
- **Arbeitsbereich** (`shared/local/local-runtime-workspace.ts`): folgt aus der
  Lizenz (`workspaceFrom(context)`) und wird mit `ensureLocalRuntimeWorkspace`
  als Nutzer, Team und Mitgliedschaft in die Datenbank geschrieben. Wechselt er,
  baut `LocalRuntimeApplication.activate` eine neue Composition; der Host bleibt.
- Warum getrennt: unterschiedliche Lebensdauer und Bedeutung. Ein Pfad im
  Arbeitsbereich müsste beim Vergleich (`sameWorkspace`) ignoriert werden und
  stünde Diensten vor der Aktivierung nicht zur Verfügung. Team-Daten trennt die
  Runtime über die `teamId` in der Datenbank, nicht über Verzeichnisse.
- Weitergabe: Nur die Kompositionsebene (Bootstrap, Application, Composition,
  API-Routen, Routen-Dienste) erhält `host`. Feature-Module bekommen daraus nur,
  was sie brauchen (z. B. `database` und `runtimeRoot` für den Task-Workflow).

## Siehe auch

- [Anfrage-Pipeline: Lizenz → Session → Route](./runtime-anfrage-pipeline.md)
- [Volumes und Datenablage](./runtime-volumes-und-datenablage.md)
