import assert from "node:assert/strict";
import {createServer, type IncomingMessage, type Server, type ServerResponse} from "node:http";
import {type AddressInfo} from "node:net";
import test from "node:test";
import {ConnectionNotFoundError} from "../../domain/entities/connection.js";
import {type ConnectionAuthorizer} from "../../domain/repositories/connection-authorizer.js";
import {type OutboundHttpRequest} from "../../domain/repositories/outbound-http-client.js";
import {OutboundHttpError} from "../outbound-http-error.js";
import {ConnectionHttpClient} from "./connection-http-client.js";

type Seen = {method: string; url: string; headers: IncomingMessage["headers"]; body: string};

async function withServer(handler: (request: Seen, response: ServerResponse) => void, run: (origin: string, seen: Seen[]) => Promise<void>): Promise<void> {
  const seen: Seen[] = [];
  const server: Server = createServer((request, response) => {
    const chunks: Buffer[] = [];
    request.on("data", (chunk: Buffer) => chunks.push(chunk));
    request.on("end", () => {
      const entry = {method: request.method ?? "", url: request.url ?? "", headers: request.headers, body: Buffer.concat(chunks).toString("utf8")};
      seen.push(entry);
      handler(entry, response);
    });
  });
  await new Promise<void>((resolveListen) => server.listen(0, "127.0.0.1", resolveListen));
  try {
    await run(`http://127.0.0.1:${(server.address() as AddressInfo).port}`, seen);
  } finally {
    server.closeAllConnections();
    await new Promise((resolveClose) => server.close(resolveClose));
  }
}

/** Ein Port, auf dem gerade nichts lauscht (fetch sperrt kleine Ports wie 1 grundsätzlich). */
async function unusedPort(): Promise<number> {
  const server = createServer();
  await new Promise<void>((resolveListen) => server.listen(0, "127.0.0.1", resolveListen));
  const port = (server.address() as AddressInfo).port;
  await new Promise((resolveClose) => server.close(resolveClose));
  return port;
}

const request = (overrides: Partial<OutboundHttpRequest> = {}): OutboundHttpRequest =>
  ({teamId: "team-1", method: "GET", url: "", query: [], headers: {}, timeoutMs: 5000, ...overrides});

const authorizerFor = (baseUrl: string, headers: Record<string, string> = {authorization: "Bearer T"}): ConnectionAuthorizer => ({
  authorize: (_team, id) => id === "c1" ? Promise.resolve({baseUrl, headers}) : Promise.reject(new ConnectionNotFoundError(id)),
});

const json = (response: ServerResponse, status: number, body: unknown, headers: Record<string, string> = {}) => {
  response.writeHead(status, {"content-type": "application/json", ...headers});
  response.end(JSON.stringify(body));
};

test("mit Verbindung: Basis-URL plus Pfad, Query kodiert, Anmeldung ergänzt und stärker als Baustein-Header", async () => {
  await withServer((seen, response) => json(response, 200, {ok: true}), async (origin, seen) => {
    const client = new ConnectionHttpClient(authorizerFor(`${origin}/api`));

    const response = await client.send(request({
      connectionId: "c1", url: "search/order", query: [{name: "q", value: "a b&c"}, {name: "", value: "ignoriert"}],
      headers: {"X-Custom": "1", Authorization: "Bearer FALSCH"},
    }));

    assert.equal(response.status, 200);
    assert.equal(response.headers["content-type"], "application/json");
    assert.equal(response.body, '{"ok":true}');
    assert.equal(seen[0].url, "/api/search/order?q=a+b%26c");
    assert.equal(seen[0].headers.authorization, "Bearer T");
    assert.equal(seen[0].headers["x-custom"], "1");
  });
});

test("ohne Verbindung: volle Adresse, Body mit Standard-Content-Type; fehlende Verbindung wird gemeldet", async () => {
  await withServer((seen, response) => json(response, 201, {}), async (origin, seen) => {
    const client = new ConnectionHttpClient(authorizerFor(origin));

    await client.send(request({method: "POST", url: `${origin}/items`, body: "hallo"}));
    assert.equal(seen[0].body, "hallo");
    assert.equal(seen[0].headers["content-type"], "text/plain; charset=utf-8");
    assert.equal(seen[0].headers.authorization, undefined);

    await client.send(request({method: "PUT", url: `${origin}/items`, body: "{}", headers: {"Content-Type": "application/json"}}));
    assert.equal(seen[1].headers["content-type"], "application/json");

    await assert.rejects(() => client.send(request({url: "/nur-pfad"})), /mit https:\/\/ oder http:\/\//);
    await assert.rejects(() => client.send(request({connectionId: "fehlt", url: "/x"})), ConnectionNotFoundError);
  });
});

test("Zugangsdaten gehen nie an eine fremde Origin: weder per URL-Feld noch per Weiterleitung", async () => {
  await withServer((seen, response) => seen.url === "/to-other-host"
    ? json(response, 302, {}, {location: `http://localhost:${response.req.socket.localPort}/geheim`})
    : json(response, 200, {}), async (origin, seen) => {
    const client = new ConnectionHttpClient(authorizerFor(`${origin}/api`));

    await assert.rejects(() => client.send(request({connectionId: "c1", url: "http://evil.example.com/steal"})), /gehört nicht zur gewählten Verbindung/);

    const redirected = await client.send(request({connectionId: "c1", url: `${origin}/to-other-host`}));
    assert.equal(redirected.status, 302, "die Weiterleitung zu einem anderen Host wird nicht verfolgt");
    assert.match(redirected.headers.location ?? "", /^http:\/\/localhost:/);
    assert.equal(seen.length, 1, "es gab keine zweite Anfrage mit den Zugangsdaten");
  });
});

test("Weiterleitungen auf derselben Origin werden verfolgt; 303 macht aus POST ein GET ohne Body", async () => {
  await withServer((seen, response) => {
    if (seen.url === "/start") json(response, 303, {}, {location: "/ziel"});
    else if (seen.url === "/schleife") json(response, 302, {}, {location: "/schleife"});
    else json(response, 200, {angekommen: seen.method});
  }, async (origin, seen) => {
    const client = new ConnectionHttpClient(authorizerFor(origin));

    const result = await client.send(request({method: "POST", url: `${origin}/start`, body: "{}", headers: {"content-type": "application/json"}}));
    assert.equal(result.body, '{"angekommen":"GET"}');
    assert.deepEqual(seen.map((entry) => `${entry.method} ${entry.url}`), ["POST /start", "GET /ziel"]);
    assert.equal(seen[1].body, "");
    assert.equal(seen[1].headers["content-type"], undefined);

    await assert.rejects(() => client.send(request({url: `${origin}/schleife`})), /zu oft weitergeleitet/);
  });
});

test("zu große Antworten, Zeitüberschreitung und Verbindungsfehler werden verständlich gemeldet — ohne Query in der Meldung", async () => {
  await withServer((seen, response) => {
    if (seen.url.startsWith("/gross")) {
      response.writeHead(200, {"content-type": "text/plain"});
      response.end(Buffer.alloc(6 * 1024 * 1024, "a"));
    } else if (seen.url.startsWith("/langsam")) {
      setTimeout(() => response.end("zu spät"), 3000).unref();
    } else response.end("{}");
  }, async (origin) => {
    const client = new ConnectionHttpClient(authorizerFor(origin));

    await assert.rejects(() => client.send(request({url: `${origin}/gross`})), /größer als 5 MB/);
    await assert.rejects(() => client.send(request({url: `${origin}/langsam?token=geheim`, timeoutMs: 200})),
      (error: unknown) => error instanceof OutboundHttpError && /nicht innerhalb von 0 Sekunden/.test(error.message) && !error.message.includes("geheim"));
    const closedPort = await unusedPort();
    await assert.rejects(() => client.send(request({url: `http://127.0.0.1:${closedPort}/x?token=geheim`})),
      (error: unknown) => error instanceof OutboundHttpError && error.message.includes(`127.0.0.1:${closedPort}`)
        && /ECONNREFUSED/.test(error.message) && !error.message.includes("geheim"));
  });
});

test("Antwort-Header ohne set-cookie; ungültige Header-Namen und Zugangsdaten in der URL werden abgelehnt", async () => {
  await withServer((seen, response) => json(response, 200, {}, {"set-cookie": "session=1", "x-rate-limit": "10"}), async (origin) => {
    const client = new ConnectionHttpClient(authorizerFor(origin));

    const response = await client.send(request({url: `${origin}/x`}));
    assert.equal(response.headers["set-cookie"], undefined);
    assert.equal(response.headers["x-rate-limit"], "10");

    await assert.rejects(() => client.send(request({url: `${origin}/x`, headers: {"Ungültig Name": "1"}})), /Header-Name/);
    await assert.rejects(() => client.send(request({url: "http://user:pass@127.0.0.1/x"})), /keine Zugangsdaten/);
    await assert.rejects(() => client.send(request({url: "http://"})), /keine gültige Adresse/);
  });
});
