# Lizenz freigeben

> `POST /v1/license/release` gibt die Lizenz beim Gateway frei, damit derselbe Token eine andere Runtime aktivieren kann.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

UI: Runtime-Einstellungen → Lizenz entfernen. Braucht nach der
Ersteinrichtung die Sitzung eines Admins.

1. Die Runtime übergibt die signierte `activationId` und ihr
   Aktivierungsgeheimnis.
2. Das Gateway vergleicht den Hash, setzt `inUse` atomar auf false.
3. Die Runtime löscht ihre lokale Aktivierung und ist gesperrt.

Eine alte signierte Lizenz lehnt das Push-Relay danach über ihre nicht mehr
aktive `activationId` ab.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
