# Noovi, das Maskottchen

> Noovi, ein freundlicher Geist, verkörpert in novooa alle Agenten: den integrierten KI-Agenten ebenso wie Orchestrator und Mitarbeiter der Teamarbeit.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- **Quelle:** `assets/images/Noovi Gestik.png`, ein Sprite-Blatt mit 3×2 Posen. Es ist nicht im Bundle, sondern dient nur als Quelle.
- **Einzelbilder:** `assets/images/noovi/noovi_<pose>.png`, je 256×256 mit transparentem Hintergrund, in `pubspec.yaml` eingetragen. Sie sind einmalig aus dem Blatt geschnitten; ändert sich das Blatt, werden sie neu geschnitten.
- **Posen** (`NooviPose`, `lib/core/widgets/noovi/`):

  | Pose | Datei | Bedeutung |
  | --- | --- | --- |
  | `wave` | `noovi_wave.png` | winkt: Begrüßung, Agent öffnen |
  | `thinking` | `noovi_thinking.png` | Hand am Kinn: denkt nach, arbeitet |
  | `cheer` | `noovi_cheer.png` | Arme ausgebreitet: freut sich, fertig |
  | `thumbsUp` | `noovi_thumbs_up.png` | Daumen hoch: bestanden |
  | `present` | `noovi_present.png` | zeigt: antwortet, präsentiert |
  | `fly` | `noovi_fly.png` | fliegt: unterwegs, bedient die Oberfläche |

- **Widgets:**
  - `NooviImage(pose, size)` ist ohne `semanticLabel` dekorativ, weil Noovi meist neben einem Text steht, der schon alles sagt.
  - `NooviThinking(size)` schwebt sanft auf und ab, steht bei reduzierten Animationen still und meldet sich Screenreadern als „Noovi denkt nach …“.
- **Beim KI-Agenten:**
  - Der Öffnen-Knopf in Kopfleiste, Aufgabenstudio und Wissensbasis zeigt `wave`.
  - Im Panel zeigt der Kopf `wave`, der leere Zustand begrüßt groß mit `wave`, und jede Agent-Antwort trägt `present` als Avatar.
  - Während der Agent arbeitet, steht `NooviThinking` statt eines Ladekreises.
  - Der Agent-Cursor im Aufgabenstudio ist `fly` mit weichem Schatten; die ausgestreckte Faust liegt auf dem Klickpunkt.
- Geplant: Noovi im Gespräch der Mitarbeiter der Teamarbeit.

## Siehe auch

- [Commands und Agent-Cursor](./agent-commands-und-cursor.md)
- [Architektur des Assistenten](./assistent-architektur.md)
