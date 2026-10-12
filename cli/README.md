# novooa Deployment CLI

Interaktive Kommandozeilen-Tool zum Deployment von novooa Backend und Flutter Client auf Windows.

## Installation

```bash
cd cli
npm install
npm run build
```

## Verwendung

```bash
npm start
# oder direkt
node dist/index.js
```

Das CLI präsentiert dann ein interaktives Menü mit folgenden Optionen:

### 1. Konfigurieren
- IP-Adresse des Windows-Rechners setzen (z.B. 192.168.0.134)
- SSH-Benutzer konfigurieren
- Repository-URL und lokaler Pfad setzen
- SSH-Verbindung testen

Konfiguration wird gespeichert in: `~/.novooa-cli/config.json`

### 2. Flutter Client auf Windows bauen
- Erfordert vorherige Konfiguration
- Klont oder aktualisiert das Repository
- Baut die Flutter Windows-App mit Dart-Defines:
  - `NOVOOA_RUNTIME=standalone`
  - `WORKSPACE_API_URL=http://<ip>:8090`
- Zeigt Pfad zur gebauten `.exe`

### 3. Lokale Runtime deployen
- Startet/stoppt Docker Compose
- Zeigt Status und Logs
- Benötigt:
  - Docker Desktop auf Windows
  - `.novooa/runtime-license-public-key`

### 4. Runtime bauen
Placeholder für zukünftige Implementierung.

## Voraussetzungen

### Windows-Rechner
- Windows 10/11 Pro oder Server
- Docker Desktop oder Docker Engine
- OpenSSH Server aktiviert (Settings → Manage optional features)
- Git für Windows
- Flutter SDK (für Build-Prozess)

### Aktueller Rechner (Mac/Linux)
- Node.js 18+
- SSH-Client (Standard auf Mac/Linux)

## SSH-Konfiguration (Windows)

1. OpenSSH Server aktivieren:
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Server~0.0.1.0
   Start-Service sshd
   Set-Service -Name sshd -StartupType Automatic
   ```

2. Firewall erlauben:
   ```powershell
   New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   ```

3. Öffentlichen Schlüssel hinzufügen (optional, für password-losen Zugriff):
   ```powershell
   # Auf dem Entwicklungs-Rechner:
   cat ~/.ssh/id_rsa.pub

   # Auf Windows-Rechner in PowerShell:
   Add-Content -Path $env:USERPROFILE\.ssh\authorized_keys -Value "<paste public key here>"
   ```

## Konfigurationsdatei

Gespeichert unter `~/.novooa-cli/config.json`:

```json
{
  "windowsHost": "192.168.0.134",
  "windowsUsername": "Administrator",
  "repoUrl": "https://github.com/arif-ertugrul/syscat2.git",
  "repoPath": "C:\\Development\\syscat2"
}
```

## Workflow-Beispiel

```bash
# 1. CLI starten
npm start

# 2. Konfigurieren
# → Konfigurieren wählen
# → IP, Benutzer, Pfade eingeben
# → SSH-Verbindung testen

# 3. Flutter bauen
# → Flutter Client auf Windows bauen
# → API-Endpoint eingeben
# → Build starten (dauert 5-10 Minuten)

# 4. Runtime starten
# → Lokale Runtime deployen
# → "Starten" wählen
# → Runtime läuft auf Port 8090

# 5. Fertig!
# → Flutter App unter build/windows/runner/Release/syscat2.exe
# → Runtime auf http://192.168.0.134:8090
```

## Fehlerbehandlung

### SSH-Verbindung fehlgeschlagen
- Windows-Firewall prüfen (Port 22)
- OpenSSH Server läuft? → `Get-Service sshd`
- Benutzername korrekt?
- IP-Adresse korrekt?

### Docker nicht gefunden
- Docker Desktop installiert?
- Docker läuft? → `docker ps` auf Windows-Rechner

### Build schlägt fehl
- Flutter SDK installiert? → `flutter --version` auf Windows
- Genug Speicherplatz?
- Logs prüfen: `npm run dev`

## Entwicklung

```bash
# Development-Modus (TypeScript direkt)
npm run dev

# Build
npm run build

# Sauber machen
npm run clean
```

## Struktur

```
cli/
  src/
    index.ts              # Hauptprogramm mit Menü
    config.ts             # Konfigurationsverwaltung
    ssh-helper.ts         # SSH-Befehle
    commands/
      configure.ts        # Konfigurationskommando
      build-flutter.ts    # Flutter-Build-Kommando
      deploy-runtime.ts   # Runtime-Deployment-Kommando
      build-runtime.ts    # Runtime-Build-Kommando (Placeholder)
  package.json
  tsconfig.json
  README.md
```

## Lizenz

MIT
