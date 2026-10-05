import assert from "node:assert/strict";
import test from "node:test";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {SkillRelayRateLimitedError} from "../../../skills/domain/entities/skill-relay-request.js";
import {PluginCatalogError} from "../../domain/entities/plugin-catalog.js";
import {type PluginCatalog} from "../../domain/repositories/plugin-catalog.js";
import {RelayPluginCatalogRequest} from "../../domain/usecases/relay-plugin-catalog-request.js";
import {LicenseRelayPluginCatalog} from "../local/license-relay-plugin-catalog.js";

const license = {signature: "s", payload: {licenseId: "lic-1"}} as unknown as SignedRuntimeLicense;

function relay(options: {valid?: boolean; allowed?: boolean} = {}) {
  const calls: string[] = [];
  const verifier: ConstructorParameters<typeof RelayPluginCatalogRequest>[0] = {verify: (value: SignedRuntimeLicense) => {
    calls.push("verify");
    return options.valid === false ? Promise.reject(new Error("abgelehnt")) : Promise.resolve(value.payload);
  }};
  const limiter = {take: (key: string) => { calls.push(`take:${key}`); return Promise.resolve({allowed: options.allowed !== false, retryAfterSeconds: 7}); }};
  const catalog: PluginCatalog = {
    list: () => { calls.push("list"); return Promise.resolve([]); },
    download: (id, version) => { calls.push(`download:${id}@${version ?? "aktuell"}`); return Promise.resolve(new Uint8Array([1])); },
  };
  return {calls, relay: new RelayPluginCatalogRequest(verifier, limiter, catalog)};
}

test("Lizenz zuerst, dann Kontingent mit eigenem Schlüssel, dann der Katalog", async () => {
  const {calls, relay: target} = relay();
  await target.list(license);
  await target.download(license, "hallo", "1.2.0");
  assert.deepEqual(calls, ["verify", "take:plugins:lic-1", "list", "verify", "take:plugins:lic-1", "download:hallo@1.2.0"]);
});

test("ungültige Lizenz, ungültige Anfrage oder erschöpftes Kontingent erreichen den Katalog nicht", async () => {
  const bad = relay({valid: false});
  await assert.rejects(() => bad.relay.list(license), /abgelehnt/);
  assert.deepEqual(bad.calls, ["verify"]);

  const invalid = relay();
  await assert.rejects(() => invalid.relay.download(license, "../etc", undefined), PluginCatalogError);
  await assert.rejects(() => invalid.relay.download(license, "hallo", "latest"), PluginCatalogError);
  assert.deepEqual(invalid.calls, []);

  const limited = relay({allowed: false});
  await assert.rejects(() => limited.relay.list(license), SkillRelayRateLimitedError);
  assert.deepEqual(limited.calls, ["verify", "take:plugins:lic-1"]);
});

test("der Runtime-Client schickt Lizenz und Aktion und übersetzt Fehlerstatus", async () => {
  const sent: unknown[] = [];
  const respond = (status: number, body: BodyInit | null, type = "application/json") => (_url: unknown, init?: RequestInit) => {
    sent.push(JSON.parse(init?.body as string));
    return Promise.resolve(new Response(body, {status, headers: {"content-type": type}}));
  };
  const client = (fetcher: typeof fetch, current: SignedRuntimeLicense | null = license) =>
    new LicenseRelayPluginCatalog("https://relay.example/plugins", () => current, fetcher);

  assert.deepEqual(await client(respond(200, JSON.stringify({items: [{id: "a"}]})) as typeof fetch).list(), [{id: "a"}]);
  assert.deepEqual(await client(respond(200, new Uint8Array([9, 8]), "application/zip") as typeof fetch).download("a", "1.0.0"), new Uint8Array([9, 8]));
  assert.deepEqual(sent[1], {license, action: "download", id: "a", version: "1.0.0"});

  await assert.rejects(() => client(respond(429, JSON.stringify({message: "Langsam"}))).list(), (error: PluginCatalogError) => error.kind === "rate_limited");
  await assert.rejects(() => client(respond(404, "{}")).download("x"), (error: PluginCatalogError) => error.kind === "not_found");
  await assert.rejects(() => client((() => Promise.reject(new TypeError("offline")))).list(), (error: PluginCatalogError) => error.kind === "unavailable");
  await assert.rejects(() => client(respond(200, "{}"), null).list(), (error: PluginCatalogError) => error.kind === "unauthorized");
  assert.throws(() => new LicenseRelayPluginCatalog("http://unsicher", () => license), /HTTPS/);
});
