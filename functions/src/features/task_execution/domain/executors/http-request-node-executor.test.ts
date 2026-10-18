import assert from "node:assert/strict";
import test from "node:test";
import {OutboundHttpError, type OutboundHttpClient, type OutboundHttpRequest, type OutboundHttpResponse} from "../../../connections/domain/repositories/outbound-http-client.js";
import {type HttpRequestNodeConfig} from "../entities/task.js";
import {type TaskRunContext} from "./node-executor.js";
import {httpRequestNodeExecutor} from "./http-request-node-executor.js";
import {succeeded} from "./node-executor-test-support.js";

const config = (overrides: Partial<HttpRequestNodeConfig> = {}): HttpRequestNodeConfig => ({
  primitive: "httpRequest", method: "GET", url: "/orders", query: [], headers: [], bodyType: "none", body: "",
  timeoutSeconds: 30, failOnHttpError: true, ...overrides,
});

const nodeOf = (nodeConfig: HttpRequestNodeConfig) =>
  ({id: "n1", primitive: "httpRequest", title: "Anfrage", description: "", outputs: [{key: "value", name: "antwort", showOnCanvas: true}], config: nodeConfig}) as never;

function contextWith(client: OutboundHttpClient | undefined): TaskRunContext {
  return {
    teamId: "team-1", outboundHttpClient: client,
    templateExpressionResolver: {resolveText: (text: string) => text.replace("{{kunde}}", "Anna")},
  } as unknown as TaskRunContext;
}

function clientReturning(response: Partial<OutboundHttpResponse> = {}) {
  const sent: OutboundHttpRequest[] = [];
  const client: OutboundHttpClient = {
    send: (request) => { sent.push(request); return Promise.resolve({status: 200, headers: {"x-a": "1"}, body: '{"id":7}', ...response}); },
  };
  return {client, sent};
}

test("löst Templates in URL, Query, Headern und Body auf und liefert typisierte Ausgaben", async () => {
  const {client, sent} = clientReturning();
  const result = succeeded(await httpRequestNodeExecutor.execute(nodeOf(config({
    connectionId: "c1", method: "POST", url: "/customers/{{kunde}}",
    query: [{name: "filter", value: "{{kunde}}"}, {name: "  ", value: "weg"}],
    headers: [{name: "X-Kunde", value: "{{kunde}}"}, {name: "", value: "weg"}],
    bodyType: "json", body: '{"name":"{{kunde}}"}',
  })), contextWith(client)));

  assert.deepEqual(sent[0], {
    teamId: "team-1", connectionId: "c1", method: "POST", url: "/customers/Anna",
    query: [{name: "filter", value: "Anna"}, {name: "", value: "weg"}],
    headers: {"X-Kunde": "Anna", "content-type": "application/json"},
    body: '{"name":"Anna"}', timeoutMs: 30_000,
  });
  assert.equal(result.status, "executed");
  assert.deepEqual(result.outputs, {
    value: {type: "json", value: {id: 7}}, status: {type: "number", value: 200},
    ok: {type: "boolean", value: true}, headers: {type: "json", value: {"x-a": "1"}},
  });
});

test("Textantworten bleiben Text, leere Antworten sind null; GET sendet nie einen Body", async () => {
  const text = clientReturning({body: "einfach Text"});
  assert.deepEqual((succeeded(await httpRequestNodeExecutor.execute(nodeOf(config({bodyType: "text", body: "ignoriert"})), contextWith(text.client)))).outputs.value,
    {type: "json", value: "einfach Text"});
  assert.equal("body" in text.sent[0], false);

  const empty = clientReturning({status: 204, body: ""});
  assert.deepEqual((succeeded(await httpRequestNodeExecutor.execute(nodeOf(config({method: "DELETE"})), contextWith(empty.client)))).outputs.value, {type: "json", value: null});
});

test("ein Fehlerstatus bricht standardmäßig ab, mit Statuscode und Auszug der Antwort", async () => {
  const {client} = clientReturning({status: 422, body: `{"errors":"${"x".repeat(500)}"}`});

  await assert.rejects(() => httpRequestNodeExecutor.execute(nodeOf(config()), contextWith(client)),
    (error: unknown) => error instanceof OutboundHttpError && /Status 422/.test(error.message) && error.message.length < 400);
});

test("ohne Abbruch bei Fehlerstatus liefert der Baustein Status und ok=false für Verzweigungen", async () => {
  const {client} = clientReturning({status: 404, body: '{"message":"nicht gefunden"}'});

  const result = succeeded(await httpRequestNodeExecutor.execute(nodeOf(config({failOnHttpError: false})), contextWith(client)));

  assert.deepEqual(result.outputs.status, {type: "number", value: 404});
  assert.deepEqual(result.outputs.ok, {type: "boolean", value: false});
  assert.deepEqual(result.outputs.value, {type: "json", value: {message: "nicht gefunden"}});
});

test("ungültiges JSON nach dem Einsetzen, fehlender Dienst und leere Verbindungs-ID", async () => {
  const {client, sent} = clientReturning();
  await assert.rejects(() => httpRequestNodeExecutor.execute(nodeOf(config({method: "POST", bodyType: "json", body: '{"a": {{kunde}}}'})), contextWith(client)), /kein gültiges JSON/);
  assert.equal(sent.length, 0, "es wird nichts gesendet");

  await assert.rejects(() => httpRequestNodeExecutor.execute(nodeOf(config()), contextWith(undefined)), /nicht verfügbar/);

  succeeded(await httpRequestNodeExecutor.execute(nodeOf(config({connectionId: ""})), contextWith(client)));
  assert.equal(sent[0].connectionId, undefined);
});
