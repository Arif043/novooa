# Regelprüfung der Runtime-Wake-ups

> Eine Runtime darf nur ihr eigenes Wake-up-Dokument lesen; alle Schreib-, Listen- und Fremdzugriffe sind abgewiesen.

Gehört zu: [Architektur](../index/architektur.md)

- `localRuntimeWakeups/{licenseId}` enthält nur `licenseId`, Revisionen und
  `updatedAt`, nie Mail- oder Push-Inhalte.
- Cloud Functions schreiben per Admin SDK (Regeln gelten dafür nicht).
- Die Runtime meldet sich per Custom Token an; das Relay prüft vorher Signatur,
  aktive Aktivierung und Aktivierungsgeheimnis.

| Angriff | Ergebnis |
| --- | --- |
| anonymer Zugriff | abgewiesen: `request.auth` nötig |
| fremde Lizenz lesen | abgewiesen: Claim `runtimeLicenseId` muss der Dokument-ID entsprechen |
| alle Wake-ups auflisten | abgewiesen: `list` verboten |
| Schreiben, Löschen, Revision manipulieren | abgewiesen: alle Client-Schreibzugriffe verboten |
| Mail-Inhalte über Listener lesen | unmöglich: nur Revisionsnummern |
| Custom Token mit kopierter Lizenz allein | abgewiesen: Hash des Aktivierungsgeheimnisses wird geprüft |
| alte Aktivierung nach Freigabe | abgewiesen: aktive, passende `activationId` nötig |

`firebase deploy --only firestore:rules --dry-run` kompiliert die Regeln; der
produktive Rollout ist ein eigener Deployment-Schritt.

## Siehe auch

- [Firebase-Wake-up der Runtime](./runtime-firebase-wakeup.md)
