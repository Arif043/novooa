# Schichtenregel

> Abhängigkeiten zeigen nach innen: Presentation kennt Domain, Domain kennt nichts außer sich selbst, Infrastructure implementiert nur Domain-Interfaces.

Gehört zu: [Architektur](../index/architektur.md)

```
┌────────────────────────────────────────────────────────┐
│ Presentation   (lib/features/*/presentation/)          │
│   Cubits / Pages / Widgets                             │
├────────────────────────────────────────────────────────┤
│ Domain          (lib/features/*/domain/)               │
│   Entities / Repository-Interfaces / UseCases          │
├────────────────────────────────────────────────────────┤
│ Infrastructure  (lib/features/*/infrastructure/)       │
│   Repository-Implementierungen (Runtime-API)           │
└────────────────────────────────────────────────────────┘
```

- `domain/` ist reines Dart: kein Flutter, kein HTTP-Client, keine Datenbank,
  kein `easy_localization`.
- Dasselbe Prinzip gilt im Backend: Runner, Executoren und Worker hängen an
  Ports; die SQLite-Adapter sind austauschbar.

## Siehe auch

- [Backend: Feature-First-Struktur](./backend-feature-first.md)
- [Runtime-Schichten](./runtime-schichten.md)
- [Lokalisierung](./lokalisierung.md)
