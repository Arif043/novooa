# Transportverschlüsselung ist Infrastruktur

> novooa authentifiziert selbst, terminiert aber kein TLS und verwaltet keine Zertifikate.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Zwei Belange werden bewusst getrennt:

- **Authentifizierung** (Passwort, Session-Token) beantwortet „wer darf diesen
  Arbeitsbereich benutzen“. Das ist Fachlogik und liegt in der Runtime,
  unabhängig vom Transport.
- **Transportverschlüsselung** ist Infrastruktur. novooa liefert keinen
  Reverse Proxy mit.

Warum: Ein mitgelieferter Proxy kollidierte mit Hosts, die schon einen Proxy
oder ein Zertifikat für ihre Domain haben, und belegte dort Port 443.

Folgen:

- Im LAN spricht der Client die Runtime über `http` im Klartext an,
  Session-Token und Inhalte eingeschlossen. Das ist nur in einem
  vertrauenswürdigen Netz zulässig.
- Ein eigener verschlüsselter Tunnel über `http` wurde wieder entfernt: Er
  schützte nur die JSON-API vor passivem Mitlesen, nicht Uploads, WebSocket
  und Web-App, und jeder Client (auch [Kunden-Dashboards](./kunden-dashboards.md))
  hätte ihn nachbauen müssen.
- Für Internetzugriff stellt der Betreiber einen eigenen
  [Reverse Proxy](./reverse-proxy-externer-zugriff.md) davor.
- novooa prüft nicht, ob vor der Runtime wirklich TLS terminiert wird, und
  erkennt keine versehentlich öffentliche Portfreigabe. Diese Zusicherung
  liegt beim Betreiber.

## Siehe auch

- [Adresse und Schema der Runtime](./runtime-adresse-schema.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
