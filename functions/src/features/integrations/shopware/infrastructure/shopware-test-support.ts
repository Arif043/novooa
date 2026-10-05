import {type OutboundHttpClient, type OutboundHttpRequest} from "../../../connections/domain/repositories/outbound-http-client.js";
import {ShopwareClient} from "./shopware-client.js";

type Reply = {status?: number; body?: unknown};
type Route = Reply | ((body: Record<string, unknown>, request: OutboundHttpRequest) => Reply);

/**
 * Nur Tests: ein Fake-Shop, der nach „METHODE /pfad“ antwortet. Jede Antwort darf eine Folge sein (erste, zweite, …);
 * die letzte gilt für alle weiteren Aufrufe. Unbekannte Routen ergeben 404, damit vergessene Aufrufe auffallen.
 */
export function fakeShopware(routes: Record<string, Route | Route[]>) {
  const sent: OutboundHttpRequest[] = [];
  const counts = new Map<string, number>();
  const http: OutboundHttpClient = {
    send: (request) => {
      sent.push(request);
      const key = `${request.method} ${request.url}`;
      const route = routes[key];
      if (route === undefined) return Promise.resolve({status: 404, headers: {}, body: JSON.stringify({errors: [{detail: `Keine Route ${key}`}]})});
      const index = counts.get(key) ?? 0;
      counts.set(key, index + 1);
      const chosen = Array.isArray(route) ? route[Math.min(index, route.length - 1)] : route;
      const reply = typeof chosen === "function" ? chosen(JSON.parse(request.body ?? "{}") as Record<string, unknown>, request) : chosen;
      const body = reply.body === undefined ? "" : typeof reply.body === "string" ? reply.body : JSON.stringify(reply.body);
      return Promise.resolve({status: reply.status ?? 200, headers: {}, body});
    },
  };
  const bodies = (key: string) => sent.filter((request) => `${request.method} ${request.url}` === key).map((request) => JSON.parse(request.body ?? "{}") as Record<string, unknown>);
  return {client: new ShopwareClient(http, "team-1", "conn-1"), http, sent, bodies};
}

export const resolveTemplates = (text: string): string => text.replace("{{nummer}}", "10001");
