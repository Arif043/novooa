import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeLicense, type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {SkillRelayRequestError} from "../../domain/entities/skill-relay-request.js";
import {type SkillsCatalogUpstream} from "../../domain/repositories/skills-catalog-upstream.js";
import {RelaySkillsCatalogRequest} from "../../domain/usecases/relay-skills-catalog-request.js";
import {HttpSkillsCatalogUpstream} from "./http-skills-catalog-upstream.js";
import {isValidSkillsRelaySignature, signSkillsRelayRequest, signatureHeader, signatureWindowMilliseconds, timestampHeader} from "./skills-relay-signature.js";

const license = {signature: "s", payload: {licenseId: "l"}} as unknown as SignedRuntimeLicense;

function relayWith(verify: RuntimeRelayLicenseVerifier["verify"], calls: string[]) {
  const upstream: SkillsCatalogUpstream = {
    get: async (pathAndQuery) => { calls.push(pathAndQuery); return {status: 200, body: "{}", headers: {}}; },
  };
  return new RelaySkillsCatalogRequest({verify}, upstream);
}

test("a valid license lets the request through to the upstream", async () => {
  const calls: string[] = [];
  const relay = relayWith(async () => ({licenseId: "l"}) as RuntimeLicense, calls);

  const response = await relay.execute(license, "/skills/search", {q: "react"});

  assert.equal(response.status, 200);
  assert.deepEqual(calls, ["/api/v1/skills/search?q=react"]);
});

test("an invalid license never reaches validation or the upstream", async () => {
  const calls: string[] = [];
  const relay = relayWith(async () => { throw new Error("Die Lizenz ist ungültig."); }, calls);

  await assert.rejects(relay.execute(license, "/skills", {}), /Lizenz/);
  await assert.rejects(relay.execute(license, "/admin", {}), /Lizenz/, "license is checked before the request");
  assert.deepEqual(calls, []);
});

test("a licensed but forbidden request is rejected without calling the upstream", async () => {
  const calls: string[] = [];
  const relay = relayWith(async () => ({licenseId: "l"}) as RuntimeLicense, calls);

  await assert.rejects(relay.execute(license, "/skills/../admin", {}), SkillRelayRequestError);
  assert.deepEqual(calls, []);
});

test("the HMAC covers timestamp, method and path with query", () => {
  const signature = signSkillsRelayRequest("geheim", 1000, "get", "/api/v1/skills?q=a");

  assert.match(signature, /^[0-9a-f]{64}$/);
  assert.equal(signature, signSkillsRelayRequest("geheim", 1000, "GET", "/api/v1/skills?q=a"));
  for (const changed of [
    signSkillsRelayRequest("anderes", 1000, "GET", "/api/v1/skills?q=a"),
    signSkillsRelayRequest("geheim", 1001, "GET", "/api/v1/skills?q=a"),
    signSkillsRelayRequest("geheim", 1000, "POST", "/api/v1/skills?q=a"),
    signSkillsRelayRequest("geheim", 1000, "GET", "/api/v1/skills?q=b"),
  ]) assert.notEqual(changed, signature);
});

test("the signature matches the shared test vector of the Vercel proxy", () => {
  assert.equal(
    signSkillsRelayRequest("geheim", 1000, "get", "/api/v1/skills/search?q=a"),
    "f09c1c1f90def0417b5dd51ac394c93458fce17ab25c5d25fec109199e78f43b",
  );
});

test("a signature is valid only inside the time window and for the exact request", () => {
  const now = 1_000_000;
  const signature = signSkillsRelayRequest("geheim", now, "GET", "/api/v1/skills");
  const valid = (offset: number, secret = "geheim", path = "/api/v1/skills", given = signature) =>
    isValidSkillsRelaySignature(secret, now, "GET", path, given, now + offset);

  assert.equal(valid(0), true);
  assert.equal(valid(signatureWindowMilliseconds), true);
  assert.equal(valid(signatureWindowMilliseconds + 1), false);
  assert.equal(valid(-signatureWindowMilliseconds - 1), false);
  assert.equal(valid(0, "falsch"), false);
  assert.equal(valid(0, "geheim", "/api/v1/skills/search"), false);
  assert.equal(valid(0, "geheim", "/api/v1/skills", "abc"), false);
  assert.equal(isValidSkillsRelaySignature("geheim", Number.NaN, "GET", "/x", signature, now), false);
});

test("the upstream client signs each call and forwards only the whitelisted headers", async () => {
  let sent: {url: string; headers: Record<string, string>} | undefined;
  const upstream = new HttpSkillsCatalogUpstream(
    () => "https://proxy.example",
    () => "geheim",
    (async (url: URL, init: RequestInit) => {
      sent = {url: String(url), headers: init.headers as Record<string, string>};
      return new Response("{\"x\":1}", {status: 429, headers: {"retry-after": "7", "set-cookie": "a=b", "x-ratelimit-remaining": "0"}});
    }) as unknown as typeof fetch,
    () => 5_000,
  );

  const response = await upstream.get("/api/v1/skills/search?q=a");

  assert.equal(sent!.url, "https://proxy.example/api/v1/skills/search?q=a");
  assert.equal(sent!.headers[timestampHeader], "5000");
  assert.equal(sent!.headers[signatureHeader], signSkillsRelayRequest("geheim", 5000, "GET", "/api/v1/skills/search?q=a"));
  assert.equal(response.status, 429);
  assert.equal(response.body, "{\"x\":1}");
  assert.equal(response.headers["retry-after"], "7");
  assert.equal(response.headers["x-ratelimit-remaining"], "0");
  assert.equal(response.headers["set-cookie"], undefined);
});
