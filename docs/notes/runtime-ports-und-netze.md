# Ports und Netze der Runtime

> Nur `novooa-runtime` veröffentlicht einen Host-Port (`8090`); ML- und Script-Dienst sind nur intern erreichbar.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **`8090`** (`NOVOOA_RUNTIME_PORT`, Container-Port 8080) auf allen
  Schnittstellen: reguläre API, Web-App und Ersteinrichtung. Clients im LAN
  geben die private IPv4-Adresse des Hosts ein.
  `NOVOOA_RUNTIME_BIND_ADDRESS=127.0.0.1` beschränkt den Zugriff auf den Host;
  mit `NOVOOA_RUNTIME_PORT=0` wählt Docker einen freien Port.
- Bei [Coolify](./coolify-deployment.md) aktiviert `NOVOOA_PROXY_ENABLED=true`
  die Traefik-Labels; `COOLIFY_PROXY_NETWORK` benennt das externe Proxy-Netz.
  Nur die Runtime der regulären Dienste verbindet sich damit; das
  Shopware-Testsystem bleibt auf das Profil `dev` beschränkt.
- **`novooa-ml`** hängt im internen Netz `novooa-ml` und zum Herunterladen von
  Katalogmodellen zusätzlich in `novooa-ml-egress`. Jede Runtime meldet sich
  dort mit ihrer Lizenz-ID an und erhält ein eigenes Token
  ([ML-Mandanten](./ml-mandanten.md)).
- **`novooa-script`** liegt in einem internen Netz ohne Außenzugang; nur die
  Runtime erreicht ihn.
- **`novooa-packages`** hängt im internen Netz `novooa-packages` (zur
  Runtime) und in `novooa-packages-egress` (zu PyPI); siehe
  [Script-Paketdienst](./script-paketdienst.md).

Port `8090` darf nie aus dem Internet erreichbar sein. Für externen Zugriff
siehe [Reverse Proxy für externen Zugriff](./reverse-proxy-externer-zugriff.md).

## Siehe auch

- [Docker-Stack der Runtime](./runtime-docker-stack.md)
- [Script-Dienst: Abschottung](./script-dienst-abschottung.md)
