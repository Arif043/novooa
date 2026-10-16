# Sammlung als Tabelle

> `tableFromCollection` liest eine ganze Datensammlung und gibt sie als `table`-Wert weiter; „Datei schreiben“ macht daraus eine `.xlsx`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Kein Filter. `table` = `{columns: string[], rows: unknown[][]}`.
- Spalten sind die Vereinigung aller Feldnamen; fehlende Felder werden je
  Zeile `null`.
- Fehlt die Sammlung, entsteht eine leere Tabelle statt eines Fehlers.

| Output | Typ | Bedeutung |
| --- | --- | --- |
| `value` | `table` | Spalten und Zeilen der Sammlung |
| `rowCount` | `number` | Anzahl gelesener Datensätze |

## Siehe auch

- [Datei-Bausteine](./datei-bausteine.md)
- [Datensatz-Bausteine](./datensatz-bausteine.md)
