import assert from "node:assert/strict";
import test from "node:test";
import Fastify from "fastify";
import {testingRoutes, testWorkspace} from "../../../../shared/local/local-runtime-http-test-support.js";
import {configureValidation} from "../../../../shared/local/local-runtime-validation.js";
import {registerWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {SkillCatalogError} from "../../domain/entities/skill-catalog.js";
import {type SkillCatalog} from "../../domain/repositories/skill-catalog.js";
import {skillCatalogRoutes} from "./local-skill-catalog-routes.js";
import {createSkillsModule, skillsShConfigFrom} from "./skills-composition.js";
import {skillRoutes} from "./local-skill-routes.js";

const catalogSkill = {id: "a/b/c", slug: "c", name: "C", source: "a/b", installs: 5, sourceType: "github", url: "https://skills.sh/a/b/c", isDuplicate: false};

function catalogWith(overrides: Partial<SkillCatalog>): SkillCatalog {
  return {search: async () => [], browse: async () => ({items: [], hasMore: false}), audits: async () => [], ...overrides};
}

test("without a configured catalog the status says so and every call explains it", async () => {
  const routes = testingRoutes(skillCatalogRoutes, {});

  const status = await routes.handle({method: "GET", url: "/v1/skills/catalog/status", body: {}});
  const search = await routes.handle({method: "GET", url: "/v1/skills/catalog/search?q=react", body: {}});

  assert.deepEqual(status?.body, {available: false});
  assert.equal(search?.statusCode, 503);
  assert.match((search?.body as {error: string}).error, /nicht eingerichtet.*GitHub, ZIP oder einen Ordner/);
});

test("search, browse and audits are forwarded to the catalog", async () => {
  const calls: unknown[] = [];
  const routes = testingRoutes(skillCatalogRoutes, {catalog: catalogWith({
    search: async (query, limit) => { calls.push(["search", query, limit]); return [catalogSkill]; },
    browse: async (view, page) => { calls.push(["browse", view, page]); return {items: [catalogSkill], hasMore: true}; },
    audits: async (id) => { calls.push(["audits", id]); return [{provider: "Socket", status: "pass", summary: "ok"}]; },
  })});

  const search = await routes.handle({method: "GET", url: "/v1/skills/catalog/search?q=react&limit=10", body: {}});
  const browse = await routes.handle({method: "GET", url: "/v1/skills/catalog/browse?view=trending&page=2", body: {}});
  const defaults = await routes.handle({method: "GET", url: "/v1/skills/catalog/browse", body: {}});
  const audits = await routes.handle({method: "GET", url: "/v1/skills/catalog/audits?id=a/b/c", body: {}});

  assert.deepEqual((search?.body as {items: unknown[]}).items, [catalogSkill]);
  assert.equal((browse?.body as {hasMore: boolean}).hasMore, true);
  assert.equal(defaults?.statusCode, 200);
  assert.deepEqual((audits?.body as {items: unknown[]}).items, [{provider: "Socket", status: "pass", summary: "ok"}]);
  assert.deepEqual(calls, [["search", "react", 10], ["browse", "trending", 2], ["browse", "all-time", 0], ["audits", "a/b/c"]]);
});

test("catalog errors become matching statuses, rate limits carry Retry-After", async (t) => {
  const search = async (error: SkillCatalogError) => {
    const http = Fastify();
    configureValidation(http);
    registerWorkspaceContext(http, () => testWorkspace());
    await http.register(skillCatalogRoutes, {catalog: catalogWith({search: async () => { throw error; }})});
    t.after(() => http.close());
    return http.inject({method: "GET", url: "/v1/skills/catalog/search?q=react"});
  };

  const limited = await search(new SkillCatalogError("Zu viele Anfragen", "rate_limited", 12));
  const invalid = await search(new SkillCatalogError("zu kurz", "invalid"));
  const down = await search(new SkillCatalogError("offline", "unavailable"));

  assert.equal(limited.statusCode, 429);
  assert.equal(limited.headers["retry-after"], "12");
  assert.equal(invalid.statusCode, 400);
  assert.equal(down.statusCode, 503);
});

test("the configuration comes from the environment: proxy URL, or token for the direct API, or nothing", () => {
  assert.equal(skillsShConfigFrom({}), undefined);
  assert.deepEqual(skillsShConfigFrom({SKILLS_SH_BASE_URL: "https://proxy.example/api/v1"}), {baseUrl: "https://proxy.example/api/v1"});
  assert.deepEqual(skillsShConfigFrom({SKILLS_SH_BASE_URL: "https://p/api/v1", SKILLS_SH_TOKEN: "t"}), {baseUrl: "https://p/api/v1", token: "t"});
  assert.deepEqual(skillsShConfigFrom({SKILLS_SH_TOKEN: "t"}), {baseUrl: "https://skills.sh/api/v1", token: "t"});
  assert.equal(skillsShConfigFrom({SKILLS_SH_TOKEN: "  "}), undefined);
});

test("importing from the catalog requires a configured catalog; with one it downloads the file tree", async () => {
  const notifier = {publish: () => undefined};
  const without = testingRoutes(skillRoutes, createSkillsModule("/tmp/ungenutzt", notifier, null).routes);
  const missing = await without.handle({method: "POST", url: "/v1/skills/imports", body: {skillsSh: {id: "a/b/c"}}});
  assert.equal(missing?.statusCode, 400);
  assert.match((missing?.body as {error: string}).error, /nicht eingerichtet/);

  const requested: string[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = (async (url: string) => {
    requested.push(url);
    return new Response(JSON.stringify({slug: "c", files: [{path: "SKILL.md", contents: "---\nname: c\ndescription: Katalog-Skill\n---\nText"}]}));
  }) as unknown as typeof fetch;
  try {
    const module = createSkillsModule("/tmp/ungenutzt-2", notifier, {baseUrl: "https://proxy.example/api/v1"});
    const preview = await testingRoutes(skillRoutes, module.routes).handle({method: "POST", url: "/v1/skills/imports", body: {skillsSh: {id: "a/b/c"}}});
    assert.equal(preview?.statusCode, 201);
    assert.deepEqual((preview?.body as {candidates: Array<{name: string}>}).candidates.map((candidate) => candidate.name), ["c"]);
    assert.deepEqual(requested, ["https://proxy.example/api/v1/skills/a/b/c"]);
  } finally {
    globalThis.fetch = original;
  }
});
