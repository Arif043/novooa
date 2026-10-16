# Regelmäßige Lizenzprüfung

> `RuntimeLicenseMonitor` fragt das Gateway etwa stündlich; nur ein ausdrückliches `revoked` sperrt die Runtime, eine Cloud-Störung nie.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Anfrage: `{action: "verify", license, activationSecret}`. Erste Prüfung
zufällig innerhalb von 15 Minuten nach dem Start, danach alle 60 Minuten plus
zufällig bis zu 15 Minuten, damit nicht alle Runtimes gleichzeitig fragen.

- `200 {status: "active"}`: weiterlaufen.
- `200 {status: "revoked"}`: Registry lehnt fachlich ab
  (`RuntimeLicenseError`: Dokument fehlt, `inUse` false, abgelaufen, fremde
  `activationId` oder falsches Geheimnis). Die Runtime löscht ihre Aktivierung
  wie bei einer Freigabe, ohne erneuten Gateway-Aufruf; danach `423`, Worker
  stehen.
- Alles andere (Netzwerkfehler, Timeout nach 15 s, Serverfehler, das `401`
  eines älteren Gateways ohne `verify`) ist **kein Urteil**: weiterlaufen und
  beim nächsten Mal erneut prüfen.

Log-Ereignisse: `local_runtime.license_revoked`,
`local_runtime.license_check_failed`.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Lizenz freigeben](./lizenz-freigabe.md)
