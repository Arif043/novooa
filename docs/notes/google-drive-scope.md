# Scope `drive.file`

> novooa fragt bei Google nur `drive.file` an: Speichern geht überall, Lesen nur bei Dateien, die novooa angelegt hat oder die im Picker freigegeben wurden.

Gehört zu: [Google Drive](../index/google-drive.md)

Angefragt werden `openid`, `email` und `drive.file`. Alle drei gelten bei
Google als nicht vertraulich; die App braucht dafür keine Verifizierung.

| Geht | Geht nicht |
| --- | --- |
| Neue Dateien in „Meine Ablage“ oder einem freigegebenen Ordner anlegen | Dateien sehen, die andere in einen freigegebenen Ordner legen |
| Freigegebene Dateien lesen | Ordner durchsuchen oder auflisten |
| Selbst angelegte Dateien lesen (ID aus „In Google Drive speichern“) | Auf Änderungen in Drive reagieren |

Warum: Die vollen Scopes `drive` und `drive.readonly` sind bei Google
„restricted“. Für den Produktivbetrieb verlangen sie eine Verifizierung mit
eigener verifizierter Domain und eventuell ein Sicherheitsaudit. Bis dahin
gälte der Testmodus mit höchstens 100 Testnutzer:innen und Anmeldungen, die
nach 7 Tagen ablaufen.

Den Auslöser für neue Dateien gibt es erst mit dem vollen Scope, siehe
[Auslöser für Google Drive](./google-drive-ausloeser.md).

## Siehe auch

- [Google-Konto verbinden](./google-konto-verbinden.md)
