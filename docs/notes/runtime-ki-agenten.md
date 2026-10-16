# KI-Agenten in der Runtime

> Der Aufgabenstudio-Agent läuft über ein Relay in der Cloud, der Wissensbasis-Agent lokal, damit Notizen das Gerät nicht verlassen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Aufgabenstudio-Agent:** Die Runtime reicht Frage und Verlauf mit ihrer
  Lizenz über `localRuntimeTaskBuilderRelay`
  (`LOCAL_RUNTIME_TASK_BUILDER_RELAY_URL`) weiter; das Modell legt die Cloud
  in Remote Config fest.
- **Wissensbasis-Agent:** läuft in der Runtime mit dem Modell, das unter
  „Sprachmodelle“ für ihn gewählt ist (sonst Standardmodell).

## Siehe auch

- [KI-Agent](../features/ki-agent.md)
- [Runtime-Adapterübersicht](./runtime-adapteruebersicht.md)
