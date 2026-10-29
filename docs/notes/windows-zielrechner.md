# Windows-Zielrechner vorbereiten

> Ein Windows-Zielrechner braucht Docker, den eingebauten OpenSSH-Server, zwei Firewall-Regeln sowie Git und Flutter; Schlüssel sind nicht vorzubereiten.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md)

1. **Docker Desktop** oder Docker Engine.
2. **OpenSSH-Server** (PowerShell als Administrator):

   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Server~0.0.1.0
   Start-Service sshd
   Set-Service -Name sshd -StartupType Automatic
   ```

3. **Firewall:**

   ```powershell
   New-NetFirewallRule -Name "SSH" -DisplayName "SSH" `
     -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   New-NetFirewallRule -Name "novooa-runtime" -DisplayName "novooa Runtime" `
     -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 8090
   ```

4. **Git und Flutter SDK** (`git --version`, `flutter --version`).
5. **Schlüssel:** nichts tun — den Master-Key erzeugt der Stack beim ersten
   Start, den öffentlichen Lizenzschlüssel enthält das Image im Code.

**SSH ohne Passwort** (empfohlen):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_novooa -N ""
cat ~/.ssh/id_novooa.pub
```

Auf Windows den Schlüssel als **eine Zeile** in
`%USERPROFILE%\.ssh\authorized_keys` eintragen und die Rechte auf den eigenen
Benutzer und `SYSTEM` beschränken:

```powershell
icacls $authKeys /inheritance:r /grant:r "${env:USERNAME}:(F)" /grant:r "SYSTEM:(F)"
```

## Siehe auch

- [SSH-Fehlersuche unter Windows](./windows-ssh-fehlersuche.md)
- [Deployment-CLI](./deployment-cli.md)
- [Ports und Netze der Runtime](./runtime-ports-und-netze.md)
