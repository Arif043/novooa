# Materialisierte nächste Ausführung

> `nextRunAt` wird am Auslöser gespeichert, damit der Worker fällige Auslöser mit einer einzigen Query findet.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Statt bei jedem Durchlauf alle Zeitpläne auszuwerten, berechnen Client und
Backend `nextRunAt` beim Speichern und nach jedem Lauf neu. Der Worker fragt
dann nur `enabled == true` und `nextRunAt <= now` ab.

Ereignis-Auslöser haben `nextRunAt = null`; sie warten auf externe
Ereignisse und tauchen in der Worker-Query nie auf.

## Siehe auch

- [Worker für fällige Auslöser](./faellige-ausloeser-worker.md)
- [Firestore-Regeln und Index für Auslöser](./ausloeser-firestore-regeln.md) — der passende Composite Index
- [Zeitplan-Wiederholungsarten](./zeitplan-wiederholungsarten.md)
