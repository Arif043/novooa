# Betriebsvarianten-Matrix

> novooa hat zwei Backends (Cloud über Firebase, Standalone über die lokale Runtime) und zwei Client-Gattungen (nativ, Web); jede Gattung soll beide Backends bedienen.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

| | Cloud | Standalone |
| --- | --- | --- |
| **Nativ** (macOS, Windows, iOS, Android) | ja | ja — Wahl zur Laufzeit, Vorgabe über `NOVOOA_RUNTIME` |
| **Web** | ja — Firebase Hosting, CI deployt bei Merge auf `main` | ja — die Runtime liefert die Web-App selbst aus |

- Nativ ist die Variante eine
  [Laufzeitentscheidung](./variantenwahl-zur-laufzeit.md); im Web entscheidet
  die [Herkunft](./web-herkunftsregel.md).
- Keine Variante ist funktional vollständig
  ([Fähigkeiten je Variante](./workspace-capabilities.md)).

Was den Umbau trägt:

- **Der Client hat keine eigene Datenbank** (kein sqflite/drift/hive/isar).
  Fachdaten laufen über Repository-Interfaces per `package:http` oder
  Firebase-SDKs; lokal nur `SharedPreferencesAsync` und
  `FlutterSecureStorage`, beide mit Web-Umsetzung.
- **Die DI-Weiche ist parametrisiert:**
  `configureDependencies({RuntimeProfile? runtimeProfile})`.
- **Das Backend ist zur Hälfte geteilt:** Domain und `infrastructure/genkit`
  gemeinsam; beide Pfade verdrahten dasselbe `createGenkitTaskWorkflow` und
  dieselbe Executor-Registry, nur die Stores unterscheiden sich.

## Siehe auch

- [Die Runtime liefert die Web-App aus](./runtime-liefert-web-app.md)
- [Zwei Identitätsmodelle](./identitaetsmodelle.md)
