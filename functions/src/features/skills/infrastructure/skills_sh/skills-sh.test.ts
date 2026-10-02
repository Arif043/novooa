import assert from "node:assert/strict";
import test from "node:test";
import {SkillCatalogError} from "../../domain/entities/skill-catalog.js";
import {SkillImportError} from "../../domain/entities/skill-import-error.js";
import {SkillsShCatalog, catalogPath} from "./skills-sh-catalog.js";
import {SkillsShClient} from "./skills-sh-client.js";
import {DirectSkillsShTransport, LicenseRelaySkillsShTransport} from "./skills-sh-transport.js";
import {SkillsShSkillSource} from "./skills-sh-skill-source.js";

type Reply = {status?: number; body?: unknown; headers?: Record<string, string>} | Error;

function harness(replies: Reply[], config = {baseUrl: "https://proxy.example/api/v1", token: "token"}) {
  const urls: string[] = [];
  const headers: Array<Record<string, string>> = [];
  const sleeps: number[] = [];
  let now = 1_000_000;
  const request = (async (url: string, init: RequestInit) => {
    urls.push(url);
    headers.push(init.headers as Record<string, string>);
    const reply = replies.shift() ?? {status: 500};
    if (reply instanceof Error) throw reply;
    return new Response(JSON.stringify(reply.body ?? {}), {status: reply.status ?? 200, headers: reply.headers});
  }) as unknown as typeof fetch;
  const client = new SkillsShClient(new DirectSkillsShTransport(config, request), {
    now: () => now, sleep: async (milliseconds) => { sleeps.push(milliseconds); now += milliseconds; },
  });
  return {client, urls, headers, sleeps, advance: (milliseconds: number) => { now += milliseconds; }};
}

test("requests carry the bearer token and encode the query", async () => {
  const {client, urls, headers} = harness([{body: {data: []}}]);

  await client.get("/skills/search", {q: "react native", limit: 5, owner: undefined});

  assert.deepEqual(urls, ["https://proxy.example/api/v1/skills/search?q=react+native&limit=5"]);
  assert.equal(headers[0].authorization, "Bearer token");
});

test("responses are cached by Cache-Control and by default, and equal parallel requests are coalesced", async () => {
  const {client, urls, advance} = harness([
    {body: {n: 1}, headers: {"cache-control": "public, max-age=30"}}, {body: {n: 2}},
  ]);

  const [first, second] = await Promise.all([client.get("/skills"), client.get("/skills")]);
  advance(29_000);
  const cached = await client.get<{n: number}>("/skills");
  advance(2_000);
  const refreshed = await client.get<{n: number}>("/skills");

  assert.deepEqual([first, second], [{n: 1}, {n: 1}]);
  assert.equal(cached.n, 1);
  assert.equal(refreshed.n, 2);
  assert.equal(urls.length, 2);
});

test("no-store responses are never cached", async () => {
  const {client, urls} = harness([{body: {n: 1}, headers: {"cache-control": "no-store"}}, {body: {n: 2}}]);

  await client.get("/skills");
  const second = await client.get<{n: number}>("/skills");

  assert.equal(second.n, 2);
  assert.equal(urls.length, 2);
});

test("a 429 waits for Retry-After and retries", async () => {
  const {client, sleeps, urls} = harness([{status: 429, headers: {"retry-after": "3"}}, {body: {ok: true}}]);

  const body = await client.get<{ok: boolean}>("/skills");

  assert.equal(body.ok, true);
  assert.deepEqual(sleeps, [3000]);
  assert.equal(urls.length, 2);
});

test("a long Retry-After is reported instead of waited for", async () => {
  const {client, sleeps} = harness([{status: 429, headers: {"retry-after": "120"}}]);

  await assert.rejects(client.get("/skills"), (error: unknown) =>
    error instanceof SkillCatalogError && error.kind === "rate_limited" && error.retryAfterSeconds === 120 && /120 Sekunden/.test(error.message));
  assert.deepEqual(sleeps, []);
});

test("repeated 429 answers stop after two retries", async () => {
  const {client, urls, sleeps} = harness([
    {status: 429, headers: {"retry-after": "1"}}, {status: 429, headers: {"retry-after": "1"}}, {status: 429, headers: {"retry-after": "1"}},
  ]);

  await assert.rejects(client.get("/skills"), (error: unknown) => error instanceof SkillCatalogError && error.kind === "rate_limited");
  assert.equal(urls.length, 3);
  assert.deepEqual(sleeps, [1000, 1000]);
});

test("an exhausted quota delays the next request until the window resets", async () => {
  const {client, sleeps} = harness([
    {body: {n: 1}, headers: {"x-ratelimit-remaining": "0", "x-ratelimit-reset": "4"}, }, {body: {n: 2}},
  ]);

  await client.get("/skills/search", {q: "aa"});
  await client.get("/skills/search", {q: "bb"});

  assert.deepEqual(sleeps, [4000]);
});

test("an exhausted quota with a long reset is reported without sending", async () => {
  const {client, urls} = harness([{body: {}, headers: {"x-ratelimit-remaining": "0", "x-ratelimit-reset": "50"}}]);

  await client.get("/skills/search", {q: "aa"});

  await assert.rejects(client.get("/skills/search", {q: "bb"}), (error: unknown) =>
    error instanceof SkillCatalogError && error.kind === "rate_limited" && error.retryAfterSeconds === 50);
  assert.equal(urls.length, 1);
});

test("503 answers are retried with backoff, then reported as unavailable", async () => {
  const retried = harness([{status: 503}, {body: {ok: true}}]);
  await retried.client.get("/skills");
  assert.deepEqual(retried.sleeps, [1000]);

  const failing = harness([{status: 503}, {status: 503}, {status: 503}]);
  await assert.rejects(failing.client.get("/skills"), (error: unknown) => error instanceof SkillCatalogError && error.kind === "unavailable");
  assert.deepEqual(failing.sleeps, [1000, 2000]);
});

test("auth, missing skills, bad requests and network errors become readable errors", async () => {
  const kinds = async (reply: Reply) => {
    try {
      await harness([reply]).client.get("/skills");
    } catch (error) {
      return error instanceof SkillCatalogError ? error.kind : "other";
    }
    return "none";
  };

  assert.equal(await kinds({status: 401}), "unauthorized");
  assert.equal(await kinds({status: 404}), "not_found");
  assert.equal(await kinds({status: 400, body: {message: "q fehlt"}}), "invalid");
  assert.equal(await kinds(new Error("offline")), "unavailable");
});

test("search validates the query length and maps results", async () => {
  const {client, urls} = harness([{body: {data: [
    {id: "expo/skills/react-native", slug: "react-native", name: "React Native", source: "expo/skills", installs: 3842, sourceType: "github", url: "https://skills.sh/x"},
    {broken: true},
  ]}}]);
  const catalog = new SkillsShCatalog(client);

  await assert.rejects(catalog.search("a"), /mindestens 2 Zeichen/);
  const results = await catalog.search("react native", 500);

  assert.deepEqual(results.map((skill) => [skill.id, skill.installs, skill.isDuplicate]), [["expo/skills/react-native", 3842, false]]);
  assert.match(urls[0], /limit=200/);
});

test("browse maps pagination and audits treat 404 as not yet audited", async () => {
  const {client} = harness([
    {body: {data: [], pagination: {hasMore: true}}},
    {status: 404},
    {body: {audits: [{provider: "Socket", status: "pass", summary: "No alerts"}, {provider: "Snyk", status: "weird", summary: "x", riskLevel: "LOW"}]}},
  ]);
  const catalog = new SkillsShCatalog(client);

  assert.deepEqual(await catalog.browse("trending", 0), {items: [], hasMore: true});
  assert.deepEqual(await catalog.audits("a/b/c"), []);
  assert.deepEqual((await catalog.audits("a/b/d")).map((audit) => [audit.provider, audit.status]), [["Socket", "pass"], ["Snyk", "warn"]]);
});

test("catalog ids are validated and encoded", () => {
  assert.equal(catalogPath("vercel-labs/skills/find skills"), "vercel-labs/skills/find%20skills");
  for (const bad of ["nur-eins", "a//b", "a/../b", ""]) assert.throws(() => catalogPath(bad), SkillCatalogError);
});

test("the skills.sh source turns the file tree into an importable skill", async () => {
  const {client} = harness([{body: {slug: "find-skills", files: [
    {path: "SKILL.md", contents: "---\nname: find-skills\ndescription: Findet Skills\n---\n# Text\n"},
    {path: "examples/a.ts", contents: "// code"},
  ]}}]);

  const found = await new SkillsShSkillSource(client).resolve({id: "vercel-labs/skills/find-skills"});

  assert.deepEqual(found.packages.map((skill) => skill.name), ["find-skills"]);
  assert.deepEqual(found.packages[0].files.map((file) => file.path).sort(), ["SKILL.md", "examples/a.ts"]);
  assert.match(found.packages[0].warnings.join(" "), /nur Textdateien/);
});

test("the skills.sh source explains missing snapshots and catalog errors", async () => {
  const noFiles = harness([{body: {slug: "x", files: null}}]);
  const missing = harness([{status: 404}]);

  await assert.rejects(new SkillsShSkillSource(noFiles.client).resolve({id: "a/b/x"}), /kein Dateiabzug/);
  await assert.rejects(new SkillsShSkillSource(missing.client).resolve({id: "a/b/x"}), (error: unknown) =>
    error instanceof SkillImportError && /nicht gefunden/.test(error.message));
});

test("the relay transport posts the license with path and query and needs an active license", async () => {
  const sent: Array<{url: string; body: Record<string, unknown>}> = [];
  const license = {signature: "s", payload: {licenseId: "l"}} as never;
  const request = (async (url: string, init: RequestInit) => {
    sent.push({url, body: JSON.parse(String(init.body))});
    return new Response(JSON.stringify({data: []}), {status: 200});
  }) as unknown as typeof fetch;
  const client = new SkillsShClient(new LicenseRelaySkillsShTransport("https://relay.example/fn", () => license, request));

  await new SkillsShCatalog(client).search("react", 5);

  assert.deepEqual(sent, [{url: "https://relay.example/fn", body: {license, path: "/skills/search", query: {q: "react", limit: "5"}}}]);

  const unlicensed = new SkillsShClient(new LicenseRelaySkillsShTransport("https://relay.example/fn", () => null, request));
  await assert.rejects(new SkillsShCatalog(unlicensed).search("react"), (error: unknown) =>
    error instanceof SkillCatalogError && error.kind === "unauthorized" && /aktive Lizenz/.test(error.message));
  assert.equal(sent.length, 1);
});

test("the relay transport requires HTTPS and passes relay rate limits through", async () => {
  assert.throws(() => new LicenseRelaySkillsShTransport("http://relay.example/fn", () => null), /HTTPS/);
  const limited = new SkillsShClient(new LicenseRelaySkillsShTransport(
    "https://relay.example/fn", () => ({}) as never,
    (async () => new Response("{}", {status: 429, headers: {"retry-after": "90"}})) as unknown as typeof fetch,
  ));

  await assert.rejects(limited.get("/skills"), (error: unknown) =>
    error instanceof SkillCatalogError && error.kind === "rate_limited" && error.retryAfterSeconds === 90);
});
