# Die Runtime liefert die Web-App aus

> Die Runtime liefert das Flutter-Web-Build unter ihrer eigenen Adresse aus; Same Origin lässt CORS, Mixed Content und Private Network Access entfallen.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

| Variable | Wirkung | Ohne Angabe |
| --- | --- | --- |
| `LOCAL_RUNTIME_WEB_DIRECTORY` | Verzeichnis des Web-Builds | Runtime bleibt reine API |
| `LOCAL_RUNTIME_ALLOWED_ORIGINS` | kommagetrennte Herkünfte mit CORS-Freigabe | keine fremde Herkunft |

- Ausgeliefert über `@fastify/static` mit SPA-Fallback auf `index.html`;
  `/v1/*` und `/healthz` werden nie von Dateien überschattet
  ([Fastify-Plugins](./runtime-fastify-plugins.md)).
- Nebeneffekt: „Browser auf `http://runtime-host:8090` öffnen“ funktioniert
  ohne Installation; die Ersteinrichtung ist der erste Bildschirm der normalen
  Web-App, auch headless (VPS, NAS, Raspberry Pi).
- **CORS** braucht es nur in der Entwicklung (`flutter run -d chrome` auf
  einem anderen Port); Standard leer, nie pauschal `*`.
- Die Runtime braucht ihre eigene Adresse nirgends: keine absoluten Links auf
  sich selbst, keine `publicUrl`; Microsoft-OAuth liegt in der Cloud. Eine
  angezeigte Adressliste in der Einrichtung war geplant, ist aber nicht umgesetzt
  — `GET /v1/setup` gibt bewusst keine Adressen aus.

## Siehe auch

- [Mixed Content im LAN](./mixed-content-im-lan.md)
- [Ersteinrichtung der Runtime](./runtime-ersteinrichtung.md)
- [Web-Herkunftsregel](./web-herkunftsregel.md)
