# Herkunft eines Laufs

> Ein Lauf merkt sich, wer ihn von Hand gestartet hat oder welcher Auslöser es war, und wer eine Freigabe oder ein Formular beantwortet hat; Rechte hängen daran nicht.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md) · [Lokale Runtime](../index/lokale-runtime.md)

- **Manueller Start:** `task_runs.started_by_uid` = angemeldete Person
  (`TaskWorkflowContext.uid` → `EnqueueTaskRunInput.startedByUid`).
- **Automatisch:** keine Person; die Herkunft steht in `source`, `trigger_id`
  und `trigger_type` (`schedule` oder `event`, auch Webhooks).
- **Freigabe/Formular:** jede angemeldete Person darf antworten;
  `task_runs.reviewed_by_uid` hält fest, wer es war
  (`approveTaskRun`/`rejectTaskRun` mit `reviewedByUid`).
- **Anzeige:** `GET /v1/activities` liefert je Aktivität
  `origin {startedBy, reviewedBy, triggerType}` mit `{uid, displayName}` der
  Personen; gelöschte Konten erscheinen als `null`. Die App zeigt bei Lauf-
  Aktivitäten z. B. „Gestartet · gestartet von Anna · beantwortet von Ben“
  oder „Erfolgreich · Zeitplan“.

## Siehe auch

- [Benutzerkonten der Runtime](./runtime-benutzerkonten.md)
- [Aktivitäten-Seite](./aktivitaeten-seite.md)
