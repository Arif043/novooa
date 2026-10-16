# Ports und Netze der Runtime

> Nur `novooa-runtime` veröffentlicht einen Host-Port (`8090`); ML- und Script-Dienst sind nur intern erreichbar.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **`8090`** (`NOVOOA_RUNTIME_PORT`, Container-Port 8080) auf allen
  Schnittstellen: reguläre API, Web-App und Ersteinrichtung. Clients im LAN
  geben die private IPv4-Adresse des Hosts ein.
- **`novooa-ml`** hängt im internen Netz `novooa-ml` und zum Herunterladen von
  Katalogmodellen zusätzlich in `novooa-ml-egress`. Jede Runtime meldet sich
  dort mit ihrer Lizenz-ID an und erhält ein eigenes Token
  ([ML-Modelle § Mandanten](../features/ml-modelle.md#mandanten)).
- **`novooa-script`** liegt in einem internen Netz ohne Außenzugang; nur die
  Runtime erreicht ihn.

Port `8090` darf nie aus dem Internet erreichbar sein. Für externen Zugriff
siehe [Reverse Proxy für externen Zugriff](./reverse-proxy-externer-zugriff.md).

## Siehe auch

- [Docker-Stack der Runtime](./runtime-docker-stack.md)
- [Script-Dienst: Abschottung](./script-dienst-abschottung.md)
