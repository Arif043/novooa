# Anfrage-Pipeline: Lizenz → Session → Route

> Lizenz- und Session-Prüfung sind `onRequest`-Hooks eines gekapselten API-Plugins; den aktiven Arbeitsbereich lesen Routen pro Anfrage aus `request.workspace`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Reihenfolge: **Lizenz → Session → Route**; keine eigene Middleware-Kette.
- `request.workspace` ist ein Getter-Decorator
  (`local-runtime-workspace-context.ts`), bedient von
  `LocalRuntimeApplication`: Team, Nutzer, team-gebundener Logger,
  Task-Workflow, globaler Modellkatalog.
- Ein Arbeitsbereichswechsel ersetzt nur Worker und diesen Kontext; Routen
  und Plugins bleiben. Realtime-Notifier und Ticket-Store sind prozessweit,
  damit Abonnements den Wechsel überdauern.
- Login und Auth-Prüfung teilen einen Session-Store, bekommen aber nur ihre
  Fähigkeit injiziert (ISP): Login `createSession`, Auth `verifySession`.
- Status, Aktivierung und Freigabe der Lizenz sind eigene öffentliche Routen.
  Die Aktivierung führt der frameworkfreie Use Case `ActivateRuntime` aus
  (Lizenz und Workspace).
- Ohne Lizenz stellt die Runtime nur `/healthz`, `GET /v1/license`,
  `POST /v1/license/activate` und `POST /v1/license/release` bereit; fachliche
  Endpunkte liefern `423`. Nach der Aktivierung legt sie den Teamarbeitsbereich
  idempotent an.

## Siehe auch

- [Betreiber-Passwort-Pflicht](./betreiber-passwort-pflicht.md)
- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Fastify-Plugins der Runtime](./runtime-fastify-plugins.md)
