# Mixed Content im LAN

> Eine über HTTPS ausgelieferte Web-App kann eine Runtime unter einer LAN-IP ohne TLS nicht erreichen; das ist eine Browsergrenze, keine Lücke.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

| Ziel aus einer HTTPS-App | Verhalten |
| --- | --- |
| `http://127.0.0.1:8090` | erlaubt (Loopback ist „potentially trustworthy“); Chrome verlangt einen Private-Network-Access-Preflight |
| `http://192.168.1.42:8090` | **hart blockiert**, kein Codefix möglich |
| `https://novooa.example.de` (eigener Proxy) | erlaubt, braucht CORS |

Im vorgesehenen Betrieb tritt der Fall nicht auf: Eine von
`http://192.168.1.42:8090` ausgelieferte App spricht dieselbe Herkunft an.
Wer Web-Clients im LAN will, nutzt dieses Same-Origin-Ausliefern oder einen
Reverse Proxy mit Zertifikat.

## Siehe auch

- [Die Runtime liefert die Web-App aus](./runtime-liefert-web-app.md)
- [Transportverschlüsselung ist Infrastruktur](./transport-ist-infrastruktur.md)
