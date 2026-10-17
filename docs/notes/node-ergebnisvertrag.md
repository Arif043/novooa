# Ergebnisvertrag eines Bausteins

> Jeder Executor liefert ein `NodeExecutionResult` mit typisierten, benannten `outputs`; der fachliche Hauptwert heißt `value`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Felder: `nodeId`, `primitive`, `status`, `outputs`.
- Typen: `string`, `datetime`, `number`, `boolean`, `json`, `file`, `media`,
  `audio`, `table`.
- `media`, `audio`, `file` sind fachliche Referenzen (`fileId`, `versionId`,
  `displayName`, `contentType`, `sizeBytes`); der Speicherort bleibt in der
  Dateiinfrastruktur, erst der konsumierende Executor liest die Version.
- Reine Seiteneffekt-Bausteine (aktuell `notificationSend`) liefern leere
  `outputs` und haben im Builder keine Werte (`WorkflowPrimitive.hasNoOutput`,
  `outputKeysOf`).
- Ein leerer Text erzeugt keinen `value`.
- `humanApproval`, `dialogInput`, `mediaInput` liefern den Status
  `waitingForApproval`; nicht registrierte Primitives `skipped` ohne Outputs.
- `value` ist der einzige primäre Schlüssel; der frühere redundante
  `text`-Output ist entfernt.
- Bausteine mit Feldern (strukturierter Prompt, Dialogeingabe, Script mit
  `workflow_output`) haben keinen `value`. Für Lauf-Ergebnis, Freigabe und
  Protokoll gilt dann ein einzelnes Feld selbst, mehrere Felder zusammen als
  JSON (`textOutputFromResult`).
- Die letzte lesbare Hauptausgabe ist das `finalOutput` des Runs.

## Siehe auch

- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
- [Registrierte Executor-Outputs](./executor-outputs.md)
