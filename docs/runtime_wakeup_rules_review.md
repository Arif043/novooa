# Runtime-Wakeup-Regelprüfung

## Modell und Zugriff

- `localRuntimeWakeups/{licenseId}` enthält nur `licenseId`,
  `communicationRevision` und `updatedAt`.
- Cloud Functions schreiben das Dokument mit dem Admin SDK; Firestore-Regeln
  gelten dafür nicht.
- Eine lokale Runtime authentifiziert sich mit einem Custom Token. Der Relay
  prüft vorher Signatur, aktive Aktivierung und Aktivierungsgeheimnis.
- Der einzige Client-Zugriff ist ein Dokument-Listener auf die eigene
  `licenseId`.

## Angriffssimulation

| Angriff | Ergebnis |
| --- | --- |
| Anonymer Zugriff | Abgewiesen: `request.auth` muss gesetzt sein. |
| Lesen einer fremden Lizenz | Abgewiesen: Claim `runtimeLicenseId` muss der Dokument-ID entsprechen. |
| Auflisten aller Wake-ups | Abgewiesen: `list` ist verboten. |
| Schreiben, Löschen oder Manipulieren einer Revision | Abgewiesen: alle Client-Schreiboperationen sind verboten. |
| Mail-Inhalte über Listener lesen | Nicht möglich: Das Dokument enthält nur eine Revisionsnummer. |
| Custom-Token-Ausstellung mit kopierter Lizenz allein | Abgewiesen: zusätzlich wird der Hash des lokalen Aktivierungsgeheimnisses geprüft. |
| Alte Aktivierung nach Lizenzfreigabe | Abgewiesen: die Registry verlangt eine aktive, passende `activationId`. |

## Validierung

`firebase deploy --only firestore:rules --dry-run` kompiliert die Regeln
erfolgreich. Der produktive Rollout der Regeln bleibt ein separater
Deployment-Schritt.
