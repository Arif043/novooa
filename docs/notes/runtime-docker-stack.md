# Docker-Stack der Runtime

> Standalone läuft als Docker-Compose-Stack je Kunde plus ein ML-Server je Rechner; Docker selbst bringt novooa nicht mit.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```text
Flutter-Desktop-App
  -> Docker Desktop / Docker Engine
      -> Stack (docker-compose.local.yaml), je Kunde einer
          -> novooa-runtime (Node)
              lokale API, Scheduler, Task-Worker, SQLite-Adapter, Relay-Client
          -> novooa-script (Python, abgeschottet)
      -> Server (docker-compose.server.yaml), einmal pro Rechner
          -> novooa-ml (Python)
              Tensor-Transformationen und ONNX-Inferenz für alle Stacks
```

- Docker Desktop (macOS, Windows) bzw. eine kompatible Docker Engine (Linux)
  ist Voraussetzung. novooa startet keine Container Engine selbst.
- Die Desktop-App spricht für Fach- und Nutzdaten nur den Runtime-Endpunkt.
  Sie braucht weder Firebase-Konto noch Internet im laufenden Betrieb; nur die
  einmalige Lizenzaktivierung braucht HTTPS zum Lizenz-Gateway.
- Die App verwaltet weder SQLite-Dateien noch Docker-Volumes.
- Container erhalten weder den Docker-Socket noch Docker-Credentials.
- Die Runtime darf ausgehend Relay und Modellprovider erreichen; der
  ML-Dienst hat keinen direkten Internetzugang.

Noch offen: Die Desktop-App soll den Stack prüfen, starten und überwachen.

## Siehe auch

- [Ports und Netze der Runtime](./runtime-ports-und-netze.md)
- [Volumes und Datenablage](./runtime-volumes-und-datenablage.md)
- [Images, Updates und Neustarts](./runtime-images-und-updates.md)
- [Lokaler Start der Runtime](./runtime-lokaler-start.md)
