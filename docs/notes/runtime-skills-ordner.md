# Skills-Ordner der Runtime

> Fähigkeiten liegen nicht in SQLite, sondern als Ordner `skills/<name>/SKILL.md` im Daten-Volume.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Pfad: `/var/lib/novooa/skills` in `novooa-data`, nicht zum Host
  freigegeben; überschreibbar mit `NOVOOA_SKILLS_DIR`. Je Skill zusätzlich
  `scripts/`, `references/`, `assets/`
  ([Spezifikation](https://agentskills.io/specification)).
- Import (GitHub, ZIP, Ordner, skills.sh) über `POST /v1/skills/imports…`
  als Vorschau mit anschließendem `commit`; Löschen über die App.
- Der skills.sh-Katalog läuft über `localRuntimeSkillsRelay` (Lizenzprüfung,
  dann HMAC zum Vercel-Proxy `relay/skills-sh-proxy`).
- Realtime-Thema `skills`.

## Siehe auch

- [Fähigkeiten](../features/skills.md) — Routen, Grenzen, Sicherheit
- [Mitarbeiter in der Runtime](./runtime-mitarbeiter.md)
