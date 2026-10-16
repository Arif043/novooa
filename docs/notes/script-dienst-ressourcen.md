# Script-Dienst: Ressourcengrenzen abstimmen

> Prozessgrenze, `pids_limit` und `mem_limit` hängen voneinander ab: `mem_limit ≈ 64 MB + Prozesse × 8 MB` plus Reserve, `pids_limit = Prozesse + 32`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Ein Script darf höchstens `SCRIPT_MAX_PROCESSES` (64) Prozesse und Threads
  belegen (`RLIMIT_NPROC`). Die Threads des Servers zählen mit, weil er
  dieselbe Benutzer-ID hat.
- `pids_limit: 96` lässt dem Server mindestens 32 Plätze für
  Anfrage-Threads, Init und Healthcheck.
- Gemessen: leerer Python-Prozess ≈ 8 MB, schlafender Thread ≈ 0,04 MB.
  64 Prozesse ≈ 512 MB, dazu ≈ 64 MB für Server und Init und Platz für Daten
  → `mem_limit: 768m` (gut ein Drittel Reserve).

Wer `SCRIPT_MAX_PROCESSES` anhebt, hebt beide Grenzen in
`docker-compose.local.yaml` mit an.

## Siehe auch

- [Script-Dienst: Ausführung und Grenzen](./script-dienst-ausfuehrung.md)
- [Script-Dienst: Abschottung](./script-dienst-abschottung.md)
