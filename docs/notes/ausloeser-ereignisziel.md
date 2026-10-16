# Ereignisziel eines Auslösers

> Alle Ereignisquellen teilen dieselbe Zielstruktur `target`; fehlt sie oder ist sie unvollständig, gilt „überall“.

Gehört zu: [Zeitplan](../index/zeitplan.md)

```ts
eventConfig: {
  source: "emailReceived" | "smsMessageReceived" | "whatsappMessageReceived"
    | "fileCreated" | "fileVersionCreated" | "fileDeleted"
    | "webhookReceived" | "shopware",
  target: { kind: "any" }                                          // Standard
    | { kind: "folder", id: string, includeSubfolders: boolean }   // Datei-Ereignisse
    | { kind: "file", id: string }                                 // Datei-Ereignisse
    | { kind: "channel", id: string }                              // SMS, WhatsApp
    | { kind: "connector", id: string },                           // E-Mail
  fileKinds: Array<"text" | "image" | "video" | "audio" | "pdf" | "spreadsheet" | "other">,
  filter: string
}
```

- `fileKinds` schränkt Datei-Ereignisse auf Kategorien ein (leer = alle).
- `filter` ist ein optionaler Textfilter: bei Nachrichten gegen den
  Nachrichtentext, bei Dateien gegen den Dateinamen.
- Der Name des Ziels wird als `label` mitgespeichert und dient nur der Anzeige.

Das Matching ist eine reine Funktion in
`scheduling/domain/usecases/event-trigger-matching.ts`.

## Siehe auch

- [Ereignisquellen-Registry](./ereignisquellen-registry.md) — Quellen mit eigener Konfiguration
- [Datei-Ereignisse auslösen Aufgaben](./datei-ereignisse-dispatch.md)
- [E-Mail-Auslöser über Mail-Connector](./email-ausloeser-mail-connector.md)
