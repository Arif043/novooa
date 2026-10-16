# Zeitplan-Wiederholungsarten

> Zeitgesteuerte Auslöser kennen nur „einmalig“, „täglich“ und „wöchentlich“; Cron-Ausdrücke gibt es im UI bewusst nicht.

Gehört zu: [Zeitplan](../index/zeitplan.md)

```ts
config: {
  kind: "once" | "daily" | "weekly",
  timezone: "Europe/Berlin",
  runAt?: Timestamp,          // once
  timeOfDay?: "09:00",        // daily
  weekdays?: number[],
  slots?: Array<{             // weekly, frei wählbare Wochenzeitpunkte
    weekday: number,
    timeOfDay: "09:00"
  }>
}
```

Wöchentliche Auslöser haben beliebig viele Zeitpunkte, z. B. „Mo 09:00“,
„Mi 14:30“ und „Fr 08:15“.

Warum kein Cron: Nutzer:innen sollen eine Routine einrichten, keine Notation
lernen. Das UI erzeugt nur diese strukturierte Konfiguration; Client und
Backend berechnen daraus `nextRunAt`.

## Siehe auch

- [Auslöser-Datenmodell](./ausloeser-datenmodell.md)
- [Materialisierte nächste Ausführung](./naechste-ausfuehrung-materialisiert.md)
- [Dialog „Auslöser hinzufügen“](./ausloeser-dialog.md)
