# Script-Dienst: Abschottung

> `novooa-script` hat kein Netz nach außen, kein Root, keine Capabilities, ein schreibgeschütztes Dateisystem und keine Schlüssel.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Aus `docker-compose.local.yaml`:

- internes Netz (`internal: true`): kein Außenzugang, kein DNS, nur die
  Runtime erreicht den Dienst;
- schreibgeschütztes Dateisystem, `tmpfs` für `/tmp` (`noexec`, `nosuid`);
- UID 65532, `cap_drop: ALL`, `no-new-privileges`;
- 768 MB Speicher, 1 CPU, 96 Prozesse;
- keine Schlüssel, keine Modelle; das Script sieht nur `PATH`.

**Läufe sind nicht voreinander versteckt (gewollt).** Alle Läufe laufen unter
derselben Benutzer-ID im selben Container; ein gleichzeitiger Lauf kann
Ordner und Anhänge eines anderen lesen und dessen Prozesse beenden.
Akzeptiert, weil auf einer Runtime nur der Betreiber Scripts schreibt. Eine
Trennung per Benutzer-ID je Lauf (Server als Root mit nur `CHOWN`, `SETUID`,
`SETGID`) wäre möglich, ist aber zurückgestellt.

## Siehe auch

- [Script-Dienst: Ressourcengrenzen abstimmen](./script-dienst-ressourcen.md)
- [Ports und Netze der Runtime](./runtime-ports-und-netze.md)
