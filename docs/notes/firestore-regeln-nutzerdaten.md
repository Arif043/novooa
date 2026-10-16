# Firestore-Regeln für Nutzerdaten

> Profile sind nur für ihre Eigentümer lesbar, Provider-Schlüssel sind für Clients nur schreibbar, und team-scoped Daten prüfen Mitgliedschaft und Form.

Gehört zu: [Architektur](../index/architektur.md)

- **`/users/{uid}`:** nach Sign-up/Sign-in vom Client angelegt bzw.
  aktualisiert; enthält PII (`email`), daher owner-only; ID == `request.auth.uid`;
  kein Listen. Felder: `uid` (unveränderlich), `email` (gültig, ≤ 254),
  `displayName` (2–120), `createdAt` (unveränderlich), `updatedAt`.
- **`/users/{uid}/settings/aiModel`:** owner-lesbare Anzeige-Metadaten
  (`provider` aus `openai`, `google_ai`, `anthropic`; `hasApiKey == true`;
  `maskedApiKey` im Format `**** 1234`; `updatedAt`).
- **`/users/{uid}/secrets/aiProvider`:** nur schreibbar (`provider`, `apiKey`
  8–4096 Zeichen, `updatedAt`); kein Lesen, Listen oder Löschen durch Clients.
  Einstellungen und Secret werden in einem Batch geschrieben.
- **Wissensnotizen:** Team-Mitglieder lesen, listen, schreiben und löschen;
  Anlage und Änderung prüfen Titel, Pfad, Typ, Inhaltsgröße, Linkanzahl und
  Zeitstempel.
- **`taskTriggers`:** siehe [Firestore-Regeln und Index für Auslöser](./ausloeser-firestore-regeln.md);
  ein referenzierter Kanal muss im selben Team existieren.
- **`communicationChannels`:** validierte WhatsApp- und SMS-Dokumente für
  Team-Mitglieder; Mail-Connectoren separat; SendGrid ist kein Nutzerkanal;
  keine Provider-Secrets in Dokumenten.
- **`localRuntimeWakeups`:** siehe
  [Regelprüfung der Runtime-Wake-ups](./runtime-wakeup-regelpruefung.md).

## Siehe auch

- [Firestore-Pfade](./firestore-pfade.md)
- [Datei-Sicherheitsregeln](./datei-sicherheitsregeln.md)
