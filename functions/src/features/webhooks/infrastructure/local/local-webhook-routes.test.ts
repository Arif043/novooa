import assert from "node:assert/strict";
import test from "node:test";
import Fastify, {type FastifyInstance} from "fastify";
import {testWorkspace} from "../../../../shared/local/local-runtime-http-test-support.js";
import {type WebhookRequest} from "../../domain/entities/webhook-event.js";
import {type WebhookReceiver, type WebhookResult} from "../../domain/usecases/receive-webhook.js";
import {webhookBodyLimit, webhookRoutes} from "./local-webhook-routes.js";

async function server(result: WebhookResult, options: {licensed?: boolean; fail?: boolean} = {}) {
  const received: WebhookRequest[] = [];
  const receiver: WebhookReceiver = {
    async receive(request) {
      if (options.fail) throw new Error("kaputt");
      received.push(request);
      return result;
    },
  };
  const app: FastifyInstance = Fastify();
  await app.register(webhookRoutes, {
    licenses: {activeContext: () => options.licensed === false ? null : ({} as never), status: () => ({state: "inactive"}) as never},
    workspaceContext: () => testWorkspace({webhooks: receiver}),
  });
  return {app, received};
}

test("ein Aufruf erreicht den Empfänger mit Rohbody, Query und Kopfzeilen und wird mit 202 beantwortet", async () => {
  const {app, received} = await server({kind: "accepted"});
  const response = await app.inject({
    method: "POST", url: "/hooks/abc/geheim?x=1&y=2", payload: '{"a":  1}',
    headers: {"content-type": "application/json", "x-test": "ja"},
  });
  assert.equal(response.statusCode, 202);
  assert.equal(response.body, "");
  assert.equal(received[0]?.triggerId, "abc");
  assert.equal(received[0]?.token, "geheim");
  assert.deepEqual(received[0]?.query, {x: "1", y: "2"});
  assert.equal(received[0]?.headers["x-test"], "ja");
  assert.equal(received[0]?.rawBody.toString(), '{"a":  1}');
});

test("auch fremde Inhaltstypen und Aufrufe ohne Body werden angenommen", async () => {
  const {app, received} = await server({kind: "accepted"});
  const xml = await app.inject({method: "POST", url: "/hooks/a/b", payload: "<a/>", headers: {"content-type": "application/xml"}});
  const empty = await app.inject({method: "PUT", url: "/hooks/a/b"});
  assert.equal(xml.statusCode, 202);
  assert.equal(empty.statusCode, 202);
  assert.equal(received[0]?.rawBody.toString(), "<a/>");
  assert.equal(received[1]?.rawBody.length, 0);
  assert.equal(received[1]?.method, "PUT");
});

test("die Einrichtungsprüfung antwortet mit reinem Text", async () => {
  const {app} = await server({kind: "echo", value: "<script>x</script>"});
  const response = await app.inject({method: "POST", url: "/hooks/a/b?validationToken=x"});
  assert.equal(response.statusCode, 200);
  assert.match(String(response.headers["content-type"]), /^text\/plain/);
  assert.equal(response.headers["x-content-type-options"], "nosniff");
  assert.equal(response.body, "<script>x</script>");
});

test("die Ergebnisse werden auf einheitliche Statuscodes abgebildet", async () => {
  const cases: Array<[WebhookResult, number]> = [
    [{kind: "notFound"}, 404], [{kind: "unauthorized"}, 401], [{kind: "badRequest"}, 400], [{kind: "rateLimited", retryAfterSeconds: 7}, 429],
  ];
  for (const [result, status] of cases) {
    const {app} = await server(result);
    const response = await app.inject({method: "POST", url: "/hooks/a/b"});
    assert.equal(response.statusCode, status, result.kind);
    if (result.kind === "rateLimited") assert.equal(response.headers["retry-after"], "7");
  }
});

test("ohne aktive Lizenz antwortet die Runtime mit 423 und fragt den Empfänger nicht", async () => {
  const {app, received} = await server({kind: "accepted"}, {licensed: false});
  const response = await app.inject({method: "POST", url: "/hooks/a/b"});
  assert.equal(response.statusCode, 423);
  assert.equal(received.length, 0);
});

test("zu große Anfragen werden mit 413 abgelehnt", async () => {
  const {app, received} = await server({kind: "accepted"});
  const response = await app.inject({
    method: "POST", url: "/hooks/a/b", payload: Buffer.alloc(webhookBodyLimit + 1), headers: {"content-type": "application/octet-stream"},
  });
  assert.equal(response.statusCode, 413);
  assert.equal(received.length, 0);
});

test("Fehler im Empfänger ergeben 500 ohne Details", async () => {
  const {app} = await server({kind: "accepted"}, {fail: true});
  const response = await app.inject({method: "POST", url: "/hooks/a/b"});
  assert.equal(response.statusCode, 500);
  assert.equal(response.body.includes("kaputt"), false);
});

test("andere Pfade und Methoden sind nicht vorhanden", async () => {
  const {app} = await server({kind: "accepted"});
  assert.equal((await app.inject({method: "DELETE", url: "/hooks/a/b"})).statusCode, 404);
  assert.equal((await app.inject({method: "POST", url: "/hooks/a"})).statusCode, 404);
});
