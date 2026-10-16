# Adresse und Schema der Runtime

> Der Client wählt das Schema an der Adresse: IP-Adresse → `http:8090`, Domain → `https:443`; eine Domain fällt nie still auf `http` zurück.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

| Adresse | Schema | Standardport | Einsatz |
| --- | --- | --- | --- |
| IP-Adresse (`192.168.1.42`) | `http` | `8090` | direkter Zugriff im vertrauenswürdigen Netz |
| Domain (`novooa.example.de`) | `https` | `443` | über eigenen Reverse Proxy mit Zertifikat |

- Ein abweichender Port lässt sich anhängen (`192.168.1.42:9000`,
  `novooa.example.de:8443`).
- Ein ausdrückliches Schema überschreibt die Vorgabe: nötig für interne
  Hostnamen ohne Zertifikat (`http://novooa.fritz.box`,
  `http://raspberrypi.local`); umgekehrt ist `https://192.168.1.42` möglich.
- **Kein stiller Downgrade:** Er würde die Verschlüsselung durch einen bloßen
  Konfigurationsfehler unbemerkt abschalten.
- Ein ungültiges Zertifikat (abgelaufen, selbstsigniert, falscher Name)
  meldet der Client ausdrücklich als Zertifikatsproblem, nicht als
  Netzwerkfehler.

## Siehe auch

- [Transportverschlüsselung ist Infrastruktur](./transport-ist-infrastruktur.md)
- [Verschlüsselter Transport über http](./verschluesselter-transport.md)
