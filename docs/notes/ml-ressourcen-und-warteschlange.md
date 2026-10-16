# Ressourcen und Warteschlange des ML-Dienstes

> Der ML-Dienst richtet sich nach den cgroup-Grenzen seines Containers und bedient Mandanten reihum über eine faire Warteschlange.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

Maßgeblich ist `cpu.max`/`memory.max` des Containers, nicht der Server.

| Wert | Standard | Variable |
|---|---|---|
| Threads je Rechnung | min(4, CPUs) | `ML_INTRA_OP_THREADS` |
| Gleichzeitige Rechnungen | CPUs ÷ Threads | `ML_COMPUTE_SLOTS` |
| Speicher für geladene Modelle | 70 % des Container-Speichers | `MODEL_SESSION_CACHE_BYTES` |
| Davon je Mandant (Teammodelle) | unbegrenzt | `MODEL_TENANT_SESSION_BYTES` |
| Gleichzeitig je Mandant | Rechenplätze − 1 | `ML_TENANT_CONCURRENCY` |
| Platte globale Bündel / je Teamspeicher | unbegrenzt | `MODEL_BUNDLE_MAX_BYTES` / `MODEL_TEAM_MAX_BYTES` |
| Mandanten | 50 | `ML_MAX_TENANTS` |

- **Vor dem Laden** verdrängt der Sitzungscache am längsten Ungenutztes (bei
  Teammodellen zuerst aus dem eigenen Anteil). Passt ein Modell nie hinein:
  `507 model_too_large`.
- **Warteschlange:** Laden, Vorverarbeitung und Inferenz laufen durch
  `FairInMemoryQueue` hinter `InferenceQueue`, je Mandant eine, reihum
  bedient. Mehr als 32 wartende Anfragen eines Mandanten oder über 5 Minuten
  Wartezeit → `429` mit `Retry-After`; die Runtime wiederholt mit wachsendem
  Abstand bis zu 2 Minuten.
- **Ein Prozess:** onnxruntime gibt während der Rechnung die Python-Sperre
  frei. Mehrere Prozesse (mit gemeinsamer Warteschlange, z. B. Redis) lohnen
  erst, wenn ein Lasttest zeigt, dass Vor- und Nachverarbeitung bremsen.

## Siehe auch

- [Schnittstelle des ML-Dienstes](./ml-dienst-schnittstelle.md)
- [ML-Mandanten](./ml-mandanten.md)
