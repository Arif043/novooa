# SSH-Fehlersuche unter Windows

> Fragt SSH trotz Schlüssel nach dem Passwort, liegt es fast immer am falschen SSH-Server, an Rechten oder am Format von `authorized_keys`.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md)

Prüfreihenfolge (PowerShell als Administrator):

1. **Welcher Server hört auf Port 22?** `netstat -ano | findstr :22`, dann
   `Get-Process -Id <PID>`. Gewünscht: `sshd.exe` (Windows OpenSSH). Git for
   Windows SSH: Git ohne OpenSSH neu installieren („native Windows Secure
   Channel library“). WSL-SSH geht auch, sonst `wsl --shutdown`.
2. **Dienst:** `Get-Service sshd`; fehlt er, installieren (Einstellungen →
   Apps → Optionale Features → OpenSSH-Server oder
   `Add-WindowsCapability`); dann starten und auf Automatisch setzen.
3. **Rechte:** `icacls` auf `.ssh` und `authorized_keys` — nur Benutzer und
   `SYSTEM` mit `(F)`, Vererbung aus (siehe
   [Windows-Zielrechner vorbereiten](./windows-zielrechner.md)).
4. **Format:** Zeile beginnt mit `ssh-ed25519 AAAA…`, genau eine Zeile je
   Schlüssel. Notfalls Datei löschen und neu schreiben:
   `… | Set-Content -Path … -Encoding UTF8 -NoNewline`.
5. **`C:\ProgramData\ssh\sshd_config`:** `PubkeyAuthentication yes`,
   `AuthorizedKeysFile .ssh/authorized_keys`; danach `Restart-Service sshd`.
6. **Logs:** `Get-WinEvent -LogName Security -MaxEvents 20 | Where-Object
   {$_.Message -like "*OpenSSH*"}`.

Vom Mac testen: `ssh -vvv -i ~/.ssh/id_ed25519 <user>@<host> "cmd /c echo OK"`
— die letzten 30 Zeilen zeigen den Grund („Server accepts key“ oder nicht).
`Write-Host` scheitert in SSH-Befehlen oft; `cmd /c echo OK` oder
`powershell -NoProfile -Command {Write-Output 'OK'}` nutzen.

Optional: `ssh-agent` als Dienst starten und `ssh-add` ausführen.

## Siehe auch

- [Windows-Zielrechner vorbereiten](./windows-zielrechner.md)
- [Deployment-CLI](./deployment-cli.md)
