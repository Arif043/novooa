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
  --name "Kunde GmbH" --expires-at 2027-09-16T00:00:00Z
```

`--expires-at` ist Pflicht, `--license-id` und `--workspace-id` optional. Die
Ausgabe ist der sechzehnstellige Token, der einmalig an den Kunden geht.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Lizenz-Signaturschlüssel](./lizenz-signaturschluessel.md)
