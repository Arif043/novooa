# Lizenz ausstellen

> Der Vertrieb erzeugt Token und gehashten Firestore-Eintrag mit `licenses:issue-local`; dafür braucht es Firebase-Admin-Zugang, aber keinen Signaturschlüssel.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Einmalig:

```bash
gcloud auth application-default login
gcloud config set project syscat-90bff
```

Ausstellen:

```bash
npm --prefix functions run licenses:issue-local -- \
  --name "Kunde GmbH" --expires-at 2027-09-16T00:00:00Z --max-users 5
```

`--expires-at` und `--max-users` (Zahl ab 1 oder `unbegrenzt`) sind Pflicht,
`--license-id` und `--workspace-id` optional. `maxUsers` steht im
Firestore-Eintrag und in jeder signierten Lizenz; Einträge ohne das Feld gelten
als ungültig.

Nutzerstaffel bestehender Lizenzen ändern:

```bash
npm --prefix functions run licenses:set-max-users -- \
  --license-id <licenseId> --max-users 15     # oder --all, oder unbegrenzt
```

Die Runtime übernimmt den Wert mit der nächsten signierten Lizenz
(Aktivierung oder [regelmäßige Prüfung](./lizenz-regelmaessige-pruefung.md)). Die
Ausgabe ist der sechzehnstellige Token, der einmalig an den Kunden geht.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Lizenz-Signaturschlüssel](./lizenz-signaturschluessel.md)
