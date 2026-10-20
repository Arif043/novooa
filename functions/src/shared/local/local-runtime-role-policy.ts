import {type RuntimeActor} from "../../features/runtime_users/domain/entities/runtime-user.js";

type Restriction = "all" | "reads" | "writes";

/**
 * Was nur Admins dürfen. Mitglieder lesen Anbindungen (für die Auswahl in Bausteinen), ändern sie aber nicht;
 * Benutzer, Import/Export und das Protokoll gehören ganz den Admins. Protokolleinträge schreibt jede App selbst.
 * Alles andere – Aufgaben, Läufe, Freigaben, Auslöser, Inhalte, Mitarbeiter, Modelle – dürfen alle.
 */
const adminRules: ReadonlyArray<{prefix: string; restriction: Restriction}> = [
  {prefix: "/v1/users", restriction: "all"},
  {prefix: "/v1/transfer", restriction: "all"},
  {prefix: "/v1/application-logs", restriction: "reads"},
  {prefix: "/v1/connections", restriction: "writes"},
  {prefix: "/v1/language-model-connections", restriction: "writes"},
  {prefix: "/v1/language-model-defaults", restriction: "writes"},
  {prefix: "/v1/language-models", restriction: "writes"},
  {prefix: "/v1/mail-connectors", restriction: "writes"},
  {prefix: "/v1/mail-relay", restriction: "writes"},
  {prefix: "/v1/script-packages", restriction: "writes"},
  {prefix: "/v1/skills", restriction: "writes"},
  {prefix: "/v1/file-settings", restriction: "writes"},
];

export function requiresAdmin(method: string, routeUrl: string): boolean {
  const reads = method === "GET" || method === "HEAD";
  return adminRules.some(({prefix, restriction}) => matches(routeUrl, prefix) &&
    (restriction === "all" || (restriction === "reads") === reads));
}

export function mayAccess(actor: RuntimeActor, method: string, routeUrl: string): boolean {
  return actor.role === "admin" || !requiresAdmin(method, routeUrl);
}

function matches(url: string, prefix: string): boolean {
  return url === prefix || url.startsWith(`${prefix}/`);
}
