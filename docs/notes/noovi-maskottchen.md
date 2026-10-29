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
  - `NooviAvatar(pose, size, ringColor)` zeigt Noovi in einem Kreis mit farbigem Ring. Die Ringfarbe sagt, welcher Agent spricht.
- **Farbring** (`AgentColors`, `lib/core/theme/agent_colors.dart`):
  - Jeder Mitarbeiter hat eine feste Farbe aus einer Palette von acht. Sie wird per FNV-1a aus seiner ID abgeleitet (nicht `String.hashCode`, der je nach Plattform abweicht) und ist überall gleich.
  - Der Orchestrator nimmt die Primärfarbe, die Prüfung `tertiary` aus dem Theme.
  - Ein Mitarbeiter erscheint als `EmployeeAvatar` (`features/employees/presentation/widgets/`).
- **Name im Gespräch:** Aufgabenstudio- und Wissensbasis-Agent stellen sich als
  „noovi“ vor (`nooviIdentity` in `assistant/infrastructure/genkit/noovi-identity.ts`,
  Rolle beider Prompts) und nennen das Sprachmodell darunter nur auf Nachfrage.
  Subagenten sprechen nie direkt mit Nutzer:innen und bleiben Fachrollen.
- **Beim KI-Agenten:**
  - Der Öffnen-Knopf in Kopfleiste, Aufgabenstudio und Wissensbasis zeigt `wave`.
  - Im Panel zeigt der Kopf `wave`, der leere Zustand begrüßt groß mit `wave`, und jede Agent-Antwort trägt `present` als Avatar.
  - Während der Agent arbeitet, steht `NooviThinking` statt eines Ladekreises.
  - Der Agent-Cursor im Aufgabenstudio ist `fly` mit weichem Schatten; die ausgestreckte Faust liegt auf dem Klickpunkt.
- **Bei den Mitarbeitern:**
  - Die Karten der Mitarbeiter-Seite zeigen den Avatar in der Pose `present`; der leere Zustand begrüßt mit `wave`.
  - Die Mitgliedskarten im Teamarbeit-Baustein, die Mitarbeiter-Zuweisung im Prompt-Baustein und die Auswahllisten zeigen ebenfalls den Avatar (`AttachmentPickerItem.leading`). Ein gelöschter Mitarbeiter zeigt weiter das Warnsymbol.
  - Im Gespräch der Mitarbeiter trägt jede Karte den Sprecher als Avatar:

    | Art | Sprecher | Pose | Ring |
    | --- | --- | --- | --- |
    | Auftrag | Orchestrator | `fly` | Orchestrator |
    | Antwort | Mitarbeiter | `present` | Mitarbeiter |
    | Auftrag gescheitert | Mitarbeiter | `thinking` | Fehlerfarbe |
    | Prüfung bestanden | Prüfung | `thumbsUp` | Prüfung |
    | Prüfung beanstandet | Prüfung | `thinking` | Prüfung |
    | Ergebnis | Orchestrator | `cheer` | Orchestrator |

- Navigationseinträge und Aktionsknöpfe („zuweisen“, „hinzufügen“) bleiben Symbole.

## Siehe auch

- [Commands und Agent-Cursor](./agent-commands-und-cursor.md)
- [Architektur des Assistenten](./assistent-architektur.md)
