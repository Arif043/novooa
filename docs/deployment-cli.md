# novooa Deployment CLI

Interaktives Kommandozeilen-Tool zur automatisierten Bereitstellung von novooa Runtime und Flutter Client auf einem entfernten Windows-Rechner.

## 🎯 Übersicht

Das Deployment CLI vereinfacht die Einrichtung einer lokalen novooa-Instanz auf Windows:

```
Entwicklungs-Rechner (Mac/Linux)
  ↓ SSH-Befehle
Windows-Rechner (192.168.0.134)
  ├─ Docker Compose Runtime (Node + Python ML)
  └─ Flutter Desktop App
```

Die CLI kümmert sich um:
- ✅ Repository-Klonen/Aktualisieren
- ✅ Flutter Windows-Build mit korrekten Dart-Defines
- ✅ Docker Compose Deployment
- ✅ Konfigurationsverwaltung
- ✅ SSH-Verbindungstests

## 🚀 Quick Start

### 1. Auf dem Entwicklungs-Rechner

```bash
# CLI starten (Mac/Linux)
./novooa-deploy.sh

# oder Windows
novooa-deploy.bat

# oder manuell
cd cli && npm install && npm run build && node dist/index.js
```

### 2. Im CLI-Menü

```
⚙️ Konfigurieren
  → IP: 192.168.0.134
  → Benutzer: Administrator (oder dein Benutzer)
  → Repo-URL: https://github.com/...
  → Pfad: C:\Development\syscat2
  → SSH-Test: ✓

🚀 Flutter Client auf Windows bauen
  → API-Endpoint: 192.168.0.134
  → Repository klonen: ja
  → (5-10 Minuten)

🐳 Lokale Runtime deployen
  → Aktion: Starten
  → (wartet auf Secrets)

✅ Fertig!
  Runtime: http://192.168.0.134:8090
  App: C:\Development\syscat2\build\windows\runner\Release\syscat2.exe
```

## 📋 Voraussetzungen

### Windows-Rechner (192.168.0.134)

1. **Docker Desktop oder Docker Engine**
   - https://www.docker.com/products/docker-desktop
   - Oder Docker Engine unter Hyper-V

2. **OpenSSH Server**
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Server~0.0.1.0
   Start-Service sshd
   Set-Service -Name sshd -StartupType Automatic
   ```

3. **Firewall**
   ```powershell
   # SSH (Port 22) erlauben
   New-NetFirewallRule -Name "SSH" -DisplayName "SSH" `
     -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

   # Runtime (Port 8090) für LAN erreichbar machen
   New-NetFirewallRule -Name "novooa-runtime" -DisplayName "novooa Runtime" `
     -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8090
   ```

4. **Git und Flutter SDK**
   ```powershell
   # Git für Windows
   # https://git-scm.com/download/win

   # Flutter SDK (für Build)
   # https://docs.flutter.dev/get-started/install/windows

   # In PowerShell prüfen:
   git --version
   flutter --version
   ```

5. **Secrets vorbereiten**
   ```powershell
   mkdir C:\Development\.novooa

   # Versionierten Runtime-Schlüsselbund mit zufälligem Master-Key erstellen
   # Im Projektverzeichnis (Node.js 24 erforderlich):
   npm --prefix functions run local-runtime:prepare -- --secret-file C:\Development\.novooa\runtime-master-key

   # runtime-license-public-key: von Produktion kopieren
   # (wird vom Lizenz-Gateway bereitgestellt)
   ```

### Entwicklungs-Rechner (Mac/Linux)

- Node.js 18+ (für CLI)
- SSH-Client (Standard vorhanden)
- Optional: SSH-Schlüsselpaar für password-los Zugriff

## 🔐 SSH-Konfiguration

### Option A: Mit Passwort (einfacher)

Das CLI fragt nach dem Passwort bei Bedarf. Stellt sicher, dass das Benutzerkonto auf Windows aktiv ist.

### Option B: Mit Schlüsselpaar (sicherer)

```bash
# Auf dem Entwicklungs-Rechner
ssh-keygen -t ed25519 -f ~/.ssh/id_novooa -N ""

# Öffentlichen Schlüssel auslesen
cat ~/.ssh/id_novooa.pub
```

```powershell
# Auf dem Windows-Rechner (PowerShell als Admin)
mkdir $env:USERPROFILE\.ssh -Force
Add-Content -Path $env:USERPROFILE\.ssh\authorized_keys `
  -Value "<paste public key here>"

# Rechte korrekt setzen
$acl = Get-Acl $env:USERPROFILE\.ssh\authorized_keys
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
  [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
  "FullControl",
  "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl -Path $env:USERPROFILE\.ssh\authorized_keys -AclObject $acl
```

## 📁 Dateiverwaltung

### Konfigurationsspeicherung

```bash
~/.novooa-cli/config.json
```

```json
{
  "windowsHost": "192.168.0.134",
  "windowsUsername": "Administrator",
  "repoUrl": "https://github.com/arif-ertugrul/syscat2.git",
  "repoPath": "C:\\Development\\syscat2"
}
```

### Build-Artefakte

```
Windows-Rechner:
  C:\Development\syscat2\
    build/windows/runner/Release/
      syscat2.exe          ← Flutter App
      syscat2.dll
      ... weitere DLLs
```

### Runtime-Daten

```
Docker Volumes: novooa-local_novooa-data (Daten), novooa-local_novooa-keys (aktueller Schlüsselbund)
  └─ SQLite: task_runs, activities, etc.
  └─ Dateien: files/{teamId}/{fileId}/...
  └─ Eigene Modelle: model-artifacts/...
Docker Volumes: novooa-local_novooa-ml-bundles (Bündel des ML-Dienstes), novooa-model-cache (Katalogmodelle, je Host geteilt)
```

## 🛠️ Workflow

### Initiales Setup

```bash
# 1. CLI starten
./novooa-deploy.sh

# 2. Konfigurieren
#    • IP eingeben
#    • Benutzer eingeben
#    • SSH-Verbindung testen

# 3. Flutter bauen
#    • API-Endpoint bestätigen
#    • Repository klonen
#    • Build starten (~5-10 min)

# 4. Runtime starten
#    • Runtime deployen
#    • Status prüfen
```

### Nachfolgende Starts

```bash
# 1. CLI starten
./novooa-deploy.sh

# 2. Runtime deployen → Starten
#    (Konfiguration ist bereits vorhanden)

# 3. App starten unter
#    C:\Development\syscat2\build\windows\runner\Release\syscat2.exe
```

### Updates

```bash
# 1. Flutter neu bauen
./novooa-deploy.sh
# → Flutter Client auf Windows bauen
# → Repository aktualisieren (git pull)
# → Build starten

# 2. Runtime aktualisieren
# → Docker Images neu bauen
docker compose -f docker-compose.local.yaml up --build --detach
```

## 🔍 Debugging

### SSH-Verbindung testen

Auf dem Entwicklungs-Rechner:
```bash
# Direkt SSH testen
ssh -v Administrator@192.168.0.134 "Write-Host 'OK'"

# Mit SSH-Schlüssel
ssh -i ~/.ssh/id_novooa Administrator@192.168.0.134 "Write-Host 'OK'"
```

### Runtime prüfen

```bash
# Auf Windows-Rechner
docker compose -f docker-compose.local.yaml ps
docker compose -f docker-compose.local.yaml logs -f

# Von außen
curl http://192.168.0.134:8090/healthz
```

### Flutter Build-Log

```bash
# Im CLI während des Builds sichtbar
# Oder im Flutter-Projekt auf Windows:
flutter build windows -v > build.log 2>&1
```

## ⚙️ Erweiterte Optionen

### Custom API-Endpoint

Falls die Runtime auf einer anderen Adresse läuft:

```bash
# Im CLI
# → Flutter Client auf Windows bauen
# → API-Endpoint: 192.168.1.100  (statt 192.168.0.134)
```

Oder manuell:
```powershell
cd C:\Development\syscat2
flutter build windows `
  --dart-define=NOVOOA_RUNTIME=standalone `
  --dart-define=WORKSPACE_API_URL=http://192.168.1.100:8090 `
  --release
```

### Ohne Docker (zukünftig)

Das CLI wird später auch ein Option zum direkten Node/Python-Start haben, falls Docker nicht verfügbar ist.

## 🐛 Häufige Fehler

| Fehler | Lösung |
|--------|--------|
| SSH-Verbindung fehlgeschlagen | Firewall prüfen, OpenSSH läuft?, IP korrekt? |
| Docker nicht gefunden | Docker Desktop installieren oder CLI konfigurieren |
| Flutter SDK nicht gefunden | Flutter SDK auf Windows installieren, PATH setzen |
| Secrets fehlen | `.novooa/runtime-master-key` und `runtime-license-public-key` anlegen |
| Build schlägt fehl | Flutter Logs prüfen: `flutter build windows -v` |

## 📝 Struktur des CLI

```
cli/
├── src/
│   ├── index.ts                 # Hauptmenü
│   ├── config.ts                # Konfigurationsverwaltung
│   ├── ssh-helper.ts            # SSH-Befehle
│   └── commands/
│       ├── configure.ts         # Konfigurationskommando
│       ├── build-flutter.ts     # Flutter-Build
│       ├── deploy-runtime.ts    # Runtime-Deployment
│       └── build-runtime.ts     # Runtime-Build (Placeholder)
├── dist/                        # Kompiliertes JavaScript
├── package.json
├── tsconfig.json
└── README.md
```

## 🚀 Nächste Schritte

- [ ] Runtime-Build-Kommando implementieren
- [ ] Automatic Docker Stack-Versionierung
- [ ] Database-Backup vor Updates
- [ ] Web-UI für Konfiguration
- [ ] License-Aktivierung integrieren
