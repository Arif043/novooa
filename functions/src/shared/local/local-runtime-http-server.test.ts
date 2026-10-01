import assert from "node:assert/strict";
import test from "node:test";
import {mkdtemp, mkdir, writeFile, rm} from "node:fs/promises";
import {join} from "node:path";
import {tmpdir} from "node:os";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";

test("health and unknown routes use native Fastify routing", async (t) => {
  const http = createLocalRuntimeHttpServer();
  t.after(() => http.close());
  assert.deepEqual((await http.inject("/healthz")).json(), {status: "ok"});
  const response = await http.inject("/v1/missing");
  assert.equal(response.statusCode, 404);
  assert.deepEqual(response.json(), {error: "Endpunkt nicht gefunden."});
});

test("Fastify handles decoded path parameters, query parameters and trailing slashes", async (t) => {
  const http = createLocalRuntimeHttpServer(async (api) => {
    api.get<{Params: {id: string}; Querystring: {limit?: string}}>("/v1/items/:id", async (request) => ({
      id: request.params.id, limit: request.query.limit,
    }));
  });
  t.after(() => http.close());
  const response = await http.inject("/v1/items/hello%20world/?limit=10");
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), {id: "hello world", limit: "10"});
});

test("native body parsing rejects invalid, oversized and poisoned JSON", async (t) => {
  let calls = 0;
  const http = createLocalRuntimeHttpServer(async (api) => {
    api.post("/v1/action", async () => { calls += 1; return {}; });
  });
  t.after(() => http.close());
  for (const payload of ["{bad", JSON.stringify({text: "x".repeat(1024 * 1024)}), '{"__proto__":{"admin":true}}']) {
    const response = await http.inject({method: "POST", url: "/v1/action", payload, headers: {"content-type": "application/json"}});
    assert.equal(response.statusCode, 400);
    assert.deepEqual(response.json(), {error: "Ungültige Anfrage.", code: "invalid_request"});
  }
  assert.equal(calls, 0);
});

test("Fastify schemas validate input before invoking controller logic", async (t) => {
  let calls = 0;
  const http = createLocalRuntimeHttpServer(async (api) => {
    api.post("/v1/action", {schema: {body: {type: "object", required: ["name"], properties: {name: {type: "string"}}}}},
      async () => { calls += 1; return {}; });
  });
  t.after(() => http.close());
  const response = await http.inject({method: "POST", url: "/v1/action", payload: {}});
  assert.equal(response.statusCode, 400);
  assert.deepEqual(response.json(), {error: "Ungültige Anfrage.", code: "invalid_request", field: "body"});
  assert.equal(calls, 0);
});

test("unexpected controller failures expose only the generic German error", async (t) => {
  const http = createLocalRuntimeHttpServer(async (api) => {
    api.get("/v1/action", async () => { throw new Error("Internal details"); });
  });
  t.after(() => http.close());
  const response = await http.inject("/v1/action");
  assert.equal(response.statusCode, 500);
  assert.deepEqual(response.json(), {error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."});
});

test("foreign requests and preflights are rejected without reflecting their origin", async (t) => {
  const http = createLocalRuntimeHttpServer();
  t.after(() => http.close());
  for (const method of ["GET", "OPTIONS"] as const) {
    const response = await http.inject({method, url: "/healthz", headers: {origin: "https://foreign.example"}});
    assert.equal(response.statusCode, 403);
    assert.equal(response.headers["access-control-allow-origin"], undefined);
  }
});

test("the official CORS plugin handles allowed preflights", async (t) => {
  const http = createLocalRuntimeHttpServer(undefined, undefined, new LocalRuntimeCorsPolicy(new Set(["http://localhost:5000"])));
  t.after(() => http.close());
  const response = await http.inject({method: "OPTIONS", url: "/v1/action", headers: {
    origin: "http://localhost:5000", "access-control-request-method": "POST",
  }});
  assert.equal(response.statusCode, 204);
  assert.equal(response.headers["access-control-allow-origin"], "http://localhost:5000");
  assert.match(String(response.headers.vary), /Origin/);
  assert.match(String(response.headers["access-control-allow-headers"]), /authorization/);
});

test("the official static plugin serves the SPA but never API paths or traversal", async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "novooa-native-web-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  await writeFile(join(directory, "index.html"), "<html>novooa</html>");
  await mkdir(join(directory, "v1"));
  await writeFile(join(directory, "v1", "secret"), "must-not-be-served");
  const http = createLocalRuntimeHttpServer(undefined, directory);
  t.after(() => http.close());
  for (const url of ["/", "/aufgaben/42", "/aufgaben/42?tab=1"]) {
    assert.equal((await http.inject(url)).body, "<html>novooa</html>");
  }
  for (const url of ["/v1/secret", "/v1%2fsecret", "/v1", "/missing.png", "/../secret.txt"]) {
    const response = await http.inject(url);
    assert.notEqual(response.body, "must-not-be-served");
    assert.equal(response.statusCode, 404);
  }
  const head = await http.inject({method: "HEAD", url: "/"});
  assert.equal(head.statusCode, 200);
  assert.equal(head.body, "");
});

test("native ONNX parser leaves the upload stream available to its handler", async (t) => {
  const http = createLocalRuntimeHttpServer(async (api) => {
    api.put("/v1/artifact", async (request) => {
      const chunks: Buffer[] = [];
      for await (const chunk of request.raw) chunks.push(Buffer.from(chunk));
      return {content: Buffer.concat(chunks).toString("utf8")};
    });
  });
  t.after(() => http.close());
  const response = await http.inject({method: "PUT", url: "/v1/artifact", payload: "onnx", headers: {"content-type": "application/onnx"}});
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.json(), {content: "onnx"});
});
