# Entwicklungsmodus ohne Lizenz

> `NOVOOA_LOCAL_DEVELOPMENT=true` schaltet die Lizenzpflicht nur für isolierte Entwicklungstests ab.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Der reguläre Compose-Start nutzt den Lizenzmodus und baut damit auch die
[Firebase-Realtime-Sitzung](./runtime-firebase-wakeup.md) auf. Im
Entwicklungsmodus meldet `GET /v1/setup` `requiresLicenseToken: false`; das
Passwort lässt sich dann ohne Lizenz-Token setzen.

## Siehe auch

- [Ersteinrichtung der Runtime](./runtime-ersteinrichtung.md)
- [Lokaler Start der Runtime](./runtime-lokaler-start.md)
