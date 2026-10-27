# Anfrage-Pipeline: Lizenz → Session → Route

> Lizenz- und Session-Prüfung sind `onRequest`-Hooks eines gekapselten API-Plugins; den aktiven Arbeitsbereich lesen Routen pro Anfrage aus `request.workspace`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Reihenfolge: **Lizenz → Session → Route**; keine eigene Middleware-Kette.
- `request.workspace` ist ein Getter-Decorator
  (`local-runtime-workspace-context.ts`), bedient von
  `LocalRuntimeApplication`: Team, Besitzer-Profil, team-gebundener Logger,
  Task-Workflow, globaler Modellkatalog.
- Ein Arbeitsbereichswechsel ersetzt nur Worker und diesen Kontext; Routen
  und Plugins bleiben. Realtime-Notifier und Ticket-Store sind prozessweit,
  damit Abonnements den Wechsel überdauern.
- Login und Auth-Prüfung teilen einen Session-Store, bekommen aber nur ihre
  Fähigkeit injiziert (ISP): Login `createSession`, Auth `verifySession`.
- Die Session-Prüfung setzt `request.actor = {uid, role}` und prüft die Rolle
  gegen `local-runtime-role-policy.ts` (`403 admin_required`, siehe
  [Benutzerkonten](./runtime-benutzerkonten.md)). Wer anfragt, lesen Routen nur
  aus `request.actor`; `request.workspace.ownerUid` ist das Profil, dem der
  Arbeitsbereich gehört.
- Status, Aktivierung und Freigabe der Lizenz sind eigene öffentliche Routen.
  Die Aktivierung führt der frameworkfreie Use Case `ActivateRuntime` aus
  (Lizenz und Workspace).
- Ohne Lizenz stellt die Runtime nur `/healthz`, `GET /v1/license`,
  `POST /v1/license/activate` und `POST /v1/license/release` bereit; fachliche
  Endpunkte liefern `423`. Nach der Aktivierung legt sie den Teamarbeitsbereich
  idempotent an.

## Siehe auch

- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Fastify-Plugins der Runtime](./runtime-fastify-plugins.md)
- [Host und Arbeitsbereich der Runtime](./runtime-host-und-arbeitsbereich.md)
