# Deployment-CLI

> Ein interaktives CLI richtet Runtime und Flutter-Client per SSH auf einem entfernten Windows-Rechner ein: klonen, bauen, Docker Compose starten.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md)

```
Entwicklungsrechner (Mac/Linux)
  ↓ SSH
Windows-Rechner
  ├─ Docker-Compose-Runtime
  └─ Flutter-Desktop-App
```

Start: `./novooa-deploy.sh`, `novooa-deploy.bat` oder
`cd cli && npm install && npm run build && node dist/index.js`
(Node.js 18+).

Menü:

1. **Konfigurieren:** IP, Benutzer, Repo-URL, Zielpfad, SSH-Test; gespeichert
   in `~/.novooa-cli/config.json` (`windowsHost`, `windowsUsername`,
   `repoUrl`, `repoPath`).
2. **Flutter-Client bauen** (5–10 min): API-Endpunkt, Repository klonen oder
   aktualisieren; Ergebnis
   `…\build\windows\runner\Release\syscat2.exe`.
3. **Runtime deployen:** Stack starten; danach `http://<ip>:8090`.

Manuell mit anderem Endpunkt:

```powershell
flutter build windows `
  --dart-define=WORKSPACE_API_URL=http://192.168.1.100:8090 `
  --release
```

Updates: Client neu bauen (git pull), Runtime mit
`docker compose -f docker-compose.local.yaml up --build --detach`.

Aufbau: `cli/src/index.ts` (Menü), `config.ts`, `ssh-helper.ts`,
`commands/{configure,build-flutter,deploy-runtime,build-runtime}.ts`
(`build-runtime` ist Platzhalter).

Offen: Runtime-Build-Kommando, Stack-Versionierung, Backup vor Updates,
Web-UI für die Konfiguration, Lizenzaktivierung, Start ohne Docker.

## Siehe auch

- [Windows-Zielrechner vorbereiten](./windows-zielrechner.md)
- [SSH-Fehlersuche unter Windows](./windows-ssh-fehlersuche.md)
- [Lokaler Start der Runtime](./runtime-lokaler-start.md)
