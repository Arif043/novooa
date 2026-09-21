# SSH-Setup auf Windows Debugging

Wenn SSH nach Passwort fragt trotz korrektem Schlüssel, folge diese Schritte.

## Symptome

```bash
# Das sollte funktionieren ohne Passwort zu fragen:
ssh -i ~/.ssh/id_ed25519 oskan@192.168.0.134 "Write-Host 'OK'"

# Aber es fragt nach Passwort:
oskan@192.168.0.134's password:
```

## Debugging auf dem Windows-Rechner

**PowerShell als Administrator öffnen und ausführen:**

### 0. Welcher SSH-Server läuft? (ERSTE PRÜFUNG!)

```powershell
# Welcher Prozess nutzt Port 22?
netstat -ano | findstr :22

# Beispiel-Output:
#   TCP    0.0.0.0:22    0.0.0.0:0    LISTENING    1234

# PID 1234 ist der Prozess. Was ist das?
Get-Process -Id 1234

# Beispiele:
# - "sshd.exe" → Windows Built-in OpenSSH ✓ (das wollen wir!)
# - "ssh-agent.exe" → Git for Windows SSH ✗ (nicht ideal)
# - "sshd" (WSL) → WSL SSH ✗ (funktioniert auch, aber kompliziert)
```

### 1. OpenSSH-Server Installation überprüfen (NÄCHSTE PRÜFUNG!)

```powershell
# Ist OpenSSH installiert?
Get-Service sshd

# Falls ERROR: "Service 'sshd' cannot be found"
# → OpenSSH MUSS zuerst installiert werden!
# → Siehe oben: "WICHTIG: Windows OpenSSH Installation"
```

### 1. OpenSSH-Server Status prüfen (nach Installation)

```powershell
# Service läuft?
Get-Service sshd

# Sollte "Running" ausgeben
# Falls nicht:
Start-Service sshd

# Auto-Start konfigurieren:
Set-Service -Name sshd -StartupType Automatic

# Nochmal prüfen
Get-Service sshd
```

### 2. SSH-Verzeichnis und Berechtigungen prüfen

```powershell
# Verzeichnis structure
$sshDir = "$env:USERPROFILE\.ssh"
$authKeys = "$sshDir\authorized_keys"

# Prüfen ob Dateien existieren
Test-Path $sshDir      # sollte True sein
Test-Path $authKeys    # sollte True sein

# Berechtigungen überprüfen
icacls $sshDir
icacls $authKeys

# Sollte zeigen: "$env:USERNAME:(F)" (vollständiger Zugriff)
```

### 3. Berechtigungen RICHTIG setzen

```powershell
# Nur dein Benutzer darf darauf zugreifen
$sshDir = "$env:USERPROFILE\.ssh"
$authKeys = "$sshDir\authorized_keys"

# SSH-Verzeichnis
icacls $sshDir /inheritance:r /grant:r "${env:USERNAME}:(F)" /grant:r "SYSTEM:(F)" | Out-Null

# authorized_keys - WICHTIG: Sehr restriktiv!
icacls $authKeys /inheritance:r /grant:r "${env:USERNAME}:(F)" /grant:r "SYSTEM:(F)" | Out-Null

# Prüfen
icacls $authKeys
# Sollte zeigen:
#   Computername\Username:(F)
#   NT AUTHORITY\SYSTEM:(F)
#   Keine anderen Einträge!
```

### 4. authorized_keys Format überprüfen

```powershell
# Inhalt anzeigen
Get-Content "$env:USERPROFILE\.ssh\authorized_keys" | Select-Object -First 5

# Sollte mit "ssh-ed25519 AAAA..." beginnen
# Wichtig: Nur EINE Zeile pro Schlüssel, kein Zeilenumbruch am Ende
```

### 5. sshd_config prüfen

```powershell
# SSH-Config öffnen
notepad "C:\ProgramData\ssh\sshd_config"

# Folgende Einstellungen prüfen/hinzufügen:
# PubkeyAuthentication yes
# AuthorizedKeysFile .ssh/authorized_keys
# PasswordAuthentication yes (optional, aber für Fallback gut)
# AllowUsers oskan (optional)

# Nach Änderungen: Service neu starten
Restart-Service sshd
```

### 6. SSH-Logs auf Windows anzeigen

```powershell
# Event Viewer öffnen:
Get-WinEvent -LogName Security -MaxEvents 20 | Where-Object {$_.Message -like "*OpenSSH*"} | Format-List

# Oder direkt nach sshd suchen:
Get-EventLog -LogName System -Source "sshd" -Newest 20
```

## Test-Befehle (vom Mac)

```bash
# Verbose SSH-Test (zeigt was passiert)
ssh -v -i ~/.ssh/id_ed25519 oskan@192.168.0.134 "Echo 'OK'"

# Mit sehr ausführlichem Debug:
ssh -vvv -i ~/.ssh/id_ed25519 oskan@192.168.0.134 "Echo 'OK'"

# Die Ausgabe sollte zeigen:
# "Offering public key: /Users/arif/.ssh/id_ed25519 RSA SHA256:..."
# "Server accepts key" oder "Authentications that can continue: publickey,password"
```

## Häufige Probleme

### Problem 0: "Service 'sshd' cannot be found" oder "Port 22 already in use"
- ✗ OpenSSH Server nicht installiert ODER anderer SSH-Server läuft
- ✓ Lösung:

**Schritt 1: Überprüfe welcher SSH-Server läuft**
```powershell
netstat -ano | findstr :22
Get-Process -Id <PID>
```

**Schritt 2: Je nachdem was das ist:**

**Fall A: Nichts läuft (Port frei)**
→ Methode 1: Settings → Apps → Optional features → OpenSSH Server installieren

**Fall B: Git for Windows SSH läuft**
→ Deinstalliere Git for Windows und installiere neu OHNE OpenSSH:
   1. Control Panel → Programs → Uninstall a program
   2. Klicke "Git for Windows" → Uninstall
   3. Neu installieren von https://git-scm.com/download/win
   4. Im Installer: Wähle "Use the native Windows Secure Channel library" (nicht OpenSSH)
   5. Danach: Methode 1 oben verwenden

**Fall C: WSL SSH läuft**
→ WSL SSH ist auch okay! Du kannst es so lassen oder:
   - WSL SSH deaktivieren: `wsl --shutdown`
   - Dann Windows OpenSSH installieren (Methode 1)

**Methode 1 (einfachste): Windows Built-in OpenSSH installieren**
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Get-Service sshd
```

### Problem 1: "Permission denied (publickey,password)"
- ✗ authorized_keys hat falsche Berechtigungen
- ✓ Lösung: icacls korrekt setzen (siehe Schritt 3)

### Problem 2: authorized_keys existiert nicht
- ✗ Datei wurde nicht angelegt
- ✓ Lösung:
  ```powershell
  New-Item -Path $env:USERPROFILE\.ssh\authorized_keys -Type File -Force
  ```

### Problem 3: Schlüssel ist in authorized_keys aber funktioniert nicht
- ✗ Falsche Zeilenumbrüche oder Extra-Zeichen
- ✓ Lösung: Schlüssel neu hinzufügen (keine Extra-Zeilenumbrüche!)
  ```powershell
  # Zuerst alte Datei löschen
  Remove-Item $env:USERPROFILE\.ssh\authorized_keys -Force

  # Neue Datei anlegen und Schlüssel einfügen (genau EINE Zeile)
  @"
ssh-ed25519 AAAA... (paste here)
"@ | Set-Content -Path $env:USERPROFILE\.ssh\authorized_keys -Encoding UTF8 -NoNewline
  ```

### Problem 4: WriteHost funktioniert nicht in SSH-Befehl
- ✗ PowerShell wird nicht korrekt initialisiert
- ✓ Lösung: Verwende stattdessen:
  ```bash
  ssh -i ~/.ssh/id_ed25519 oskan@192.168.0.134 "cmd /c echo OK"
  # oder
  ssh -i ~/.ssh/id_ed25519 oskan@192.168.0.134 "powershell -NoProfile -Command {Write-Output 'OK'}"
  ```

## ⚠️ WICHTIG: Windows OpenSSH Installation

**Falls `Get-Service sshd` "Service not found" zeigt:**

### Methode 1: Windows Optional Features (empfohlen)

```powershell
# PowerShell als Administrator öffnen!

# OpenSSH Server installieren
Add-WindowsCapability -Online -Name OpenSSH.Server~0.0.1.0

# OpenSSH Client (falls nicht vorhanden)
Add-WindowsCapability -Online -Name OpenSSH.Client~0.0.1.0

# Service starten
Start-Service sshd

# Auto-Start aktivieren
Set-Service -Name sshd -StartupType Automatic

# Prüfen (sollte "Running" zeigen)
Get-Service sshd
```

### Methode 2: Wenn Portkonflikt bei Chocolatey

Falls choco Error "Port 22 already in use":

```powershell
# 1. Prüfen welcher SSH-Server läuft
netstat -ano | findstr :22

# 2. Prozess-ID (PID) anzeigen, z.B. "1234"
# 3. Prüfen was das ist
Get-Process -Id 1234

# 4. Wenn das nicht Windows OpenSSH sein soll: deinstallieren
# z.B. für Git Bash SSH:
#   Deinstalliere "Git for Windows" aus Control Panel
#   (oder wähle nur Git ohne OpenSSH)

# 5. Danach Methode 1 (Windows Features) verwenden!
```

### Methode 3: Mit Scoop

```powershell
# Scoop installieren (falls noch nicht)
# https://scoop.sh/

# OpenSSH installieren
scoop install openssh

# Service starten (manuell notwendig)
Start-Service sshd
```

### Methode 4: Manuelle Installation (Windows 10/11)

1. Öffne **Settings → Apps → Optional features**
2. Klicke auf **"View features"**
3. Suche nach **"OpenSSH Server"**
4. Klicke darauf und **Install**
5. Nach Installation: PowerShell als Admin
   ```powershell
   Start-Service sshd
   Set-Service -Name sshd -StartupType Automatic
   ```

## SSH-Agent konfigurieren (optional, für Windows)

```powershell
# SSH-Agent Service starten
Start-Service ssh-agent

# Auto-Start konfigurieren
Set-Service -Name ssh-agent -StartupType Automatic

# Schlüssel hinzufügen
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

## Finale Checkliste

- [ ] OpenSSH Server installiert und läuft
- [ ] Firewall erlaubt Port 22 (SSH)
- [ ] `authorized_keys` existiert mit korrekten Berechtigungen
- [ ] Öffentlicher Schlüssel ist in `authorized_keys` enthalten
- [ ] Berechtigungen: nur Username + SYSTEM haben Zugriff
- [ ] `sshd_config` hat `PubkeyAuthentication yes`
- [ ] Test funktioniert: `ssh -i key user@host "cmd /c echo OK"`

## Support-Befehl für uns

Falls immer noch nicht funktioniert, bitte zeige uns:

```bash
# Von deinem Mac:
ssh -vvv -i ~/.ssh/id_ed25519 oskan@192.168.0.134 "cmd /c echo OK" 2>&1 | tail -30
```

Kopiere die letzten 30 Zeilen – dort ist die Fehlermeldung.
