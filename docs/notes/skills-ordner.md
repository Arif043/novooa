# Skills-Ordner

> Fähigkeiten liegen nicht in einer Datenbank, sondern als Ordner `skills/<name>/SKILL.md` im Datenverzeichnis der Runtime; der Ordnername ist die Kennung.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md) · [Lokale Runtime](../index/lokale-runtime.md)

```text
<skills-ordner>/
├── pdf-verarbeitung/
│   ├── SKILL.md
│   ├── references/REFERENCE.md
│   └── scripts/extract.py
└── code-review/
    └── SKILL.md
```

- Name, Beschreibung, Lizenz und Kompatibilität liest die App aus dem Kopf der
  `SKILL.md`. Ordner ohne `SKILL.md` und versteckte Ordner werden ignoriert;
  Skills mit Problemen (fehlende Beschreibung, abweichender Name) erscheinen
  mit Warnung statt zu verschwinden.
- Ort: `/var/lib/novooa/skills` im Volume `novooa-data`, nicht zum Host
  freigegeben. `NOVOOA_SKILLS_DIR` verlegt ihn (nur Sonderfälle wie Tests).
- Skills kommen nur über den Import herein und werden in der App gelöscht;
  keine Bearbeitung von außen.
- Die Seite **Fähigkeiten** zeigt den Pfad (kopierbar) und „Neu einlesen“.
- Realtime-Thema `skills`.

## Siehe auch

- [Skill-Format (agentskills.io)](./skill-format.md)
- [Skills importieren](./skills-import.md)
- [Volumes und Datenablage der Runtime](./runtime-volumes-und-datenablage.md)
