import assert from "node:assert/strict";
import {randomBytes} from "node:crypto";
import {resolve} from "node:path";
import test from "node:test";
import {eq} from "drizzle-orm";
import {type RuntimeDatabase} from "../../../../db/database.js";
import {connections, languageModelSecrets, teams} from "../../../../db/schema.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";
import {CredentialCipher} from "../../../communication/infrastructure/security/credential-cipher.js";
import {EncryptedSQLiteLanguageModelSecretStore} from "../../../language_models/infrastructure/local/encrypted-sqlite-language-model-secret-store.js";
import {ConnectionAuthError, ConnectionNotFoundError, ConnectionRequestError, type ConnectionInput} from "../../domain/entities/connection.js";
import {connectionRoutes} from "./local-connection-routes.js";
import {OAuthTokenProvider} from "./oauth-token-provider.js";
import {SQLiteConnectionStore} from "./sqlite-connection-store.js";
import {StoredConnectionAuthorizer} from "./stored-connection-authorizer.js";

const bearer: ConnectionInput = {name: "Shop", baseUrl: "https://shop.example.com/api", auth: {kind: "bearer"}};
const oauth: ConnectionInput = {
  name: "Shop OAuth", baseUrl: "https://shop.example.com/api",
  auth: {kind: "oauthClientCredentials", tokenUrl: "https://shop.example.com/api/oauth/token", clientId: "client-1", scope: "write"},
};

async function setup() {
  const database = await openLocalRuntimeDatabase({databasePath: ":memory:", migrationsDirectory: resolve(__dirname, "../../../../../drizzle")});
  for (const id of ["team-1", "team-2"]) await database.insert(teams).values({id, name: id, owner_uid: "u"});
  const secrets = new EncryptedSQLiteLanguageModelSecretStore(database, new CredentialCipher(randomBytes(32).toString("base64")));
  return {database, store: new SQLiteConnectionStore(database, secrets)};
}

const closing = (database: RuntimeDatabase) => ({[Symbol.dispose]: () => database.$client.close()});

test("das Geheimnis wird verschlüsselt abgelegt und nur über loadSecret gelesen", async () => {
  const {database, store} = await setup();
  using _ = closing(database);

  const created = await store.create("team-1", bearer, "super-geheim");

  assert.deepEqual((await store.list("team-1")).map((connection) => connection.name), ["Shop"]);
  assert.equal(await store.loadSecret("team-1", created.id), "super-geheim");
  const stored = await database.select().from(languageModelSecrets).where(eq(languageModelSecrets.secret_ref, `connection/team-1/${created.id}`)).get();
  assert.ok(stored, "das Geheimnis liegt in der Tabelle, die auch die Schlüsselrotation umwrappt");
  assert.equal(stored.encrypted_value.includes("super-geheim"), false);
  assert.equal(JSON.stringify(created).includes("super-geheim"), false);
});

test("Teams sehen und ändern nur ihre eigenen Verbindungen", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const created = await store.create("team-1", bearer, "geheim");

  assert.deepEqual(await store.list("team-2"), []);
  assert.equal(await store.find("team-2", created.id), undefined);
  await assert.rejects(() => store.update("team-2", created.id, bearer), ConnectionNotFoundError);
  await assert.rejects(() => store.loadSecret("team-2", created.id), ConnectionNotFoundError);
  await store.delete("team-2", created.id);
  assert.equal((await store.list("team-1")).length, 1);
});

test("Ändern ohne Geheimnis behält es, mit Geheimnis ersetzt es; Wechsel der Anmeldeart braucht ein neues", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const created = await store.create("team-1", bearer, "alt");

  const renamed = await store.update("team-1", created.id, {...bearer, name: "Neu"});
  assert.equal(renamed.name, "Neu");
  assert.equal(await store.loadSecret("team-1", created.id), "alt");
  assert.notEqual(renamed.updatedAt, created.updatedAt);

  await store.update("team-1", created.id, bearer, "neu");
  assert.equal(await store.loadSecret("team-1", created.id), "neu");

  await assert.rejects(() => store.update("team-1", created.id, oauth), (error: unknown) => error instanceof ConnectionRequestError && /neues Geheimnis/.test(error.message));
  assert.equal((await store.update("team-1", created.id, oauth, "client-secret")).auth.kind, "oauthClientCredentials");
});

test("Löschen entfernt Verbindung und Geheimnis und ist wiederholbar", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const created = await store.create("team-1", bearer, "geheim");

  await store.delete("team-1", created.id);
  await store.delete("team-1", created.id);

  assert.deepEqual(await database.select().from(connections).all(), []);
  assert.deepEqual(await database.select().from(languageModelSecrets).all(), []);
});

test("die Anmeldung erzeugt je nach Art die passende Kopfzeile", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const authorizer = new StoredConnectionAuthorizer(store, new OAuthTokenProvider());
  const key = await store.create("team-1", {...bearer, auth: {kind: "apiKey", headerName: "X-API-Key"}}, "k-1");
  const token = await store.create("team-1", bearer, "t-1");

  assert.deepEqual(await authorizer.authorize("team-1", key.id), {baseUrl: "https://shop.example.com/api", headers: {"x-api-key": "k-1"}});
  assert.deepEqual((await authorizer.authorize("team-1", token.id)).headers, {authorization: "Bearer t-1"});
  await assert.rejects(() => authorizer.authorize("team-1", "fehlt"), ConnectionNotFoundError);
});

type TokenCall = {url: string; form: URLSearchParams; headers: Headers};

function tokenServer(responses: Array<{status?: number; body: unknown}>, calls: TokenCall[]): typeof fetch {
  return ((url: string, init: RequestInit) => {
    calls.push({url, form: new URLSearchParams(init.body as URLSearchParams), headers: new Headers(init.headers)});
    const next = responses[Math.min(calls.length - 1, responses.length - 1)];
    return Promise.resolve(new Response(JSON.stringify(next.body), {status: next.status ?? 200}));
  }) as typeof fetch;
}

test("OAuth: Token holen, zwischenspeichern, kurz vor Ablauf erneuern, nach Bearbeitung neu holen", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const calls: TokenCall[] = [];
  let now = 1_000_000;
  const tokens = new OAuthTokenProvider(tokenServer([
    {body: {access_token: "tok-1", expires_in: 600}}, {body: {access_token: "tok-2", expires_in: 600}}, {body: {access_token: "tok-3", expires_in: 600}},
  ], calls), () => now);
  const authorizer = new StoredConnectionAuthorizer(store, tokens);
  const created = await store.create("team-1", oauth, "client-secret");

  assert.equal((await authorizer.authorize("team-1", created.id)).headers.authorization, "Bearer tok-1");
  assert.equal((await authorizer.authorize("team-1", created.id)).headers.authorization, "Bearer tok-1");
  assert.equal(calls.length, 1, "zweiter Aufruf kommt aus dem Zwischenspeicher");
  assert.equal(calls[0].url, "https://shop.example.com/api/oauth/token");
  assert.deepEqual(Object.fromEntries(calls[0].form), {grant_type: "client_credentials", client_id: "client-1", client_secret: "client-secret", scope: "write"});
  assert.equal(calls[0].headers.get("content-type"), "application/x-www-form-urlencoded");

  now += 600_000 - 30_000;
  assert.equal((await authorizer.authorize("team-1", created.id)).headers.authorization, "Bearer tok-2", "innerhalb der Sicherheitsreserve wird erneuert");

  await new Promise((resolveTick) => setTimeout(resolveTick, 2));
  await store.update("team-1", created.id, {...oauth, name: "Umbenannt"});
  assert.equal((await authorizer.authorize("team-1", created.id)).headers.authorization, "Bearer tok-3", "eine Bearbeitung verwirft das alte Token");
});

test("OAuth: das Format json sendet die Token-Anfrage als JSON (Shopware) und überlebt das Speichern", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const sent: Array<{body: unknown; contentType: string | null}> = [];
  const request = ((_url: string, init: RequestInit) => {
    sent.push({body: JSON.parse(init.body as string), contentType: new Headers(init.headers).get("content-type")});
    return Promise.resolve(new Response(JSON.stringify({access_token: "tok", expires_in: 600}), {status: 200}));
  }) as unknown as typeof fetch;
  const created = await store.create("team-1", {...oauth, auth: {...oauth.auth, tokenRequestFormat: "json"} as ConnectionInput["auth"]}, "client-secret");

  const authorizer = new StoredConnectionAuthorizer(store, new OAuthTokenProvider(request));
  assert.equal((await authorizer.authorize("team-1", created.id)).headers.authorization, "Bearer tok");

  assert.deepEqual(sent, [{
    body: {grant_type: "client_credentials", client_id: "client-1", client_secret: "client-secret", scope: "write"},
    contentType: "application/json",
  }]);
  const stored = (await store.find("team-1", created.id))?.auth;
  assert.equal(stored?.kind === "oauthClientCredentials" ? stored.tokenRequestFormat : undefined, "json");
});

test("OAuth: gleichzeitige Aufrufe teilen sich eine Token-Anfrage", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const calls: TokenCall[] = [];
  const authorizer = new StoredConnectionAuthorizer(store, new OAuthTokenProvider(tokenServer([{body: {access_token: "tok", expires_in: 600}}], calls)));
  const created = await store.create("team-1", oauth, "client-secret");

  await Promise.all([authorizer.authorize("team-1", created.id), authorizer.authorize("team-1", created.id), authorizer.authorize("team-1", created.id)]);

  assert.equal(calls.length, 1);
});

test("OAuth: Fehler nennen Status und Grund, aber nie das Geheimnis", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const created = await store.create("team-1", oauth, "client-secret-xyz");
  const failing = (status: number, body: unknown) => new StoredConnectionAuthorizer(store, new OAuthTokenProvider(tokenServer([{status, body}], [])));

  await assert.rejects(() => failing(401, {error: "invalid_client", error_description: "Client authentication failed"}).authorize("team-1", created.id),
    (error: unknown) => error instanceof ConnectionAuthError && /Shop OAuth/.test(error.message) && /401/.test(error.message)
      && /Client authentication failed/.test(error.message) && !error.message.includes("client-secret-xyz"));
  await assert.rejects(() => failing(200, {kein: "token"}).authorize("team-1", created.id), ConnectionAuthError);

  const offline = new StoredConnectionAuthorizer(store, new OAuthTokenProvider((() => Promise.reject(new TypeError("offline")))));
  await assert.rejects(() => offline.authorize("team-1", created.id), /nicht erreichbar/);
});

test("Routen: nie ein Geheimnis in Antworten, Fehler als 400/404, Änderungen werden gemeldet", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const topics: string[] = [];
  const notifier = Object.assign(new LocalRuntimeRealtimeNotifier(), {publish: (topic: string) => { topics.push(topic); }});
  const routes = testingRoutes(connectionRoutes, {store, notifier, client: {send: () => Promise.reject(new Error("nicht erwartet"))}}, {teamId: "team-1"});
  const body = {name: "Shop", baseUrl: "https://shop.example.com/api/", auth: {kind: "apiKey", headerName: "X-API-Key"}, secret: "supergeheim"};

  const created = await routes.handle({method: "POST", url: "/v1/connections", body});
  assert.equal(created?.statusCode, 201);
  const id = (created?.body as {id: string}).id;
  assert.equal((created?.body as {baseUrl: string}).baseUrl, "https://shop.example.com/api");
  assert.equal(JSON.stringify(created?.body).includes("supergeheim"), false);

  const listed = await routes.handle({url: "/v1/connections", body: {}});
  assert.equal(JSON.stringify(listed?.body).includes("supergeheim"), false);
  assert.equal((listed?.body as {items: unknown[]}).items.length, 1);

  assert.equal((await routes.handle({method: "POST", url: "/v1/connections", body: {...body, secret: undefined}}))?.statusCode, 400);
  assert.equal((await routes.handle({method: "POST", url: "/v1/connections", body: {...body, baseUrl: "kaputt"}}))?.statusCode, 400);

  const renamed = await routes.handle({method: "PUT", url: `/v1/connections/${id}`, body: {...body, name: "Neu", secret: ""}});
  assert.equal(renamed?.statusCode, 200);
  assert.equal(await store.loadSecret("team-1", id), "supergeheim", "leeres Geheimnis lässt das gespeicherte unverändert");
  assert.equal((await routes.handle({method: "PUT", url: "/v1/connections/gibts-nicht", body}))?.statusCode, 404);

  assert.equal((await routes.handle({method: "DELETE", url: `/v1/connections/${id}`, body: {}}))?.statusCode, 200);
  assert.deepEqual((await routes.handle({url: "/v1/connections", body: {}}))?.body, {items: []});
  assert.deepEqual(topics, ["connections", "connections", "connections"]);
});

test("Verbindung testen: meldet Erfolg, Fehlerstatus mit Hinweis und Anmeldefehler — immer mit 200", async () => {
  const {database, store} = await setup();
  using _ = closing(database);
  const created = await store.create("team-1", bearer, "geheim");
  const sent: Array<{connectionId?: string; url: string; method: string}> = [];
  const respond = (behaviour: () => Promise<{status: number; headers: Record<string, string>; body: string}>) => testingRoutes(connectionRoutes, {
    store, notifier: new LocalRuntimeRealtimeNotifier(),
    client: {send: (request) => { sent.push(request); return behaviour(); }},
  }, {teamId: "team-1"});
  const call = (routes: ReturnType<typeof respond>, id: string, body: object = {}) =>
    routes.handle({method: "POST", url: `/v1/connections/${id}/test`, body});

  const ok = await call(respond(() => Promise.resolve({status: 200, headers: {}, body: ""})), created.id, {path: "/ping"});
  assert.deepEqual(ok?.body, {ok: true, status: 200, message: "Verbindung funktioniert (Status 200)."});
  assert.deepEqual(sent[0], {...sent[0], connectionId: created.id, url: "/ping", method: "GET"});

  const denied = await call(respond(() => Promise.resolve({status: 401, headers: {}, body: ""})), created.id);
  assert.equal(denied?.statusCode, 200);
  assert.match((denied?.body as {message: string}).message, /Status 401.*Zugangsdaten/);
  const missing = await call(respond(() => Promise.resolve({status: 404, headers: {}, body: ""})), created.id);
  assert.match((missing?.body as {message: string}).message, /Test-Pfad/);

  const failing = await call(respond(() => Promise.reject(new ConnectionAuthError("Die Anmeldung bei „Shop“ ist fehlgeschlagen."))), created.id);
  assert.deepEqual(failing?.body, {ok: false, message: "Die Anmeldung bei „Shop“ ist fehlgeschlagen."});

  assert.equal((await call(respond(() => Promise.reject(new Error("nie"))), "gibts-nicht"))?.statusCode, 404);
});
