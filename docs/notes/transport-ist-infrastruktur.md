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

- Im LAN spricht der Client die Runtime über `http` an; die JSON-API ist dann
  über den [verschlüsselten Transport](./verschluesselter-transport.md)
  gegen passives Mitlesen geschützt.
- Für Internetzugriff stellt der Betreiber einen eigenen
  [Reverse Proxy](./reverse-proxy-externer-zugriff.md) davor.
- novooa prüft nicht, ob vor der Runtime wirklich TLS terminiert wird, und
  erkennt keine versehentlich öffentliche Portfreigabe. Diese Zusicherung
  liegt beim Betreiber.

## Siehe auch

- [Adresse und Schema der Runtime](./runtime-adresse-schema.md)
- [Betreiber-Passwort-Pflicht](./betreiber-passwort-pflicht.md)
