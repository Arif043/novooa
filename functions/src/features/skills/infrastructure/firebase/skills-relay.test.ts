import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeLicense, type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type RuntimeRelayLicenseVerifier} from "../../../licensing/domain/repositories/runtime-relay-license-verifier.js";
import {SkillRelayRateLimitedError, SkillRelayRequestError} from "../../domain/entities/skill-relay-request.js";
import {type RateLimiter} from "../../../../shared/rate_limiting/domain/repositories/rate-limiter.js";
import {type SkillsCatalogUpstream} from "../../domain/repositories/skills-catalog-upstream.js";
import {RelaySkillsCatalogRequest} from "../../domain/usecases/relay-skills-catalog-request.js";
import {HttpSkillsCatalogUpstream} from "./http-skills-catalog-upstream.js";
import {isValidSkillsRelaySignature, signSkillsRelayRequest, signatureHeader, signatureWindowMilliseconds, timestampHeader} from "./skills-relay-signature.js";

const license = {signature: "s", payload: {licenseId: "l"}} as unknown as SignedRuntimeLicense;

const allowAll: RateLimiter = {take: async () => ({allowed: true, retryAfterSeconds: 0})};

function relayWith(verify: RuntimeRelayLicenseVerifier["verify"], calls: string[], limiter: RateLimiter = allowAll) {
  const upstream: SkillsCatalogUpstream = {
    get: async (request) => { calls.push(`${request.path}?${new URLSearchParams(request.query)}`); return {status: 200, body: "{}", headers: {}}; },
  };
  return new RelaySkillsCatalogRequest({verify}, limiter, upstream);
}

test("a valid license lets the request through to the upstream", async () => {
  const calls: string[] = [];
  const relay = relayWith(async () => ({licenseId: "l"}) as RuntimeLicense, calls);

  const response = await relay.execute(license, "/skills/search", {q: "react"});

  assert.equal(response.status, 200);
  assert.deepEqual(calls, ["/skills/search?q=react"]);
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

test("tokens are taken per license, only after license and request are valid", async () => {
  const taken: string[] = [];
  const limiter: RateLimiter = {take: async (key) => { taken.push(key); return {allowed: true, retryAfterSeconds: 0}; }};
  const calls: string[] = [];
  const relay = relayWith(async () => ({licenseId: "lizenz-1"}) as RuntimeLicense, calls, limiter);
  const rejecting = relayWith(async () => { throw new Error("Die Lizenz ist ungültig."); }, calls, limiter);

  await relay.execute(license, "/skills", {});
  await assert.rejects(relay.execute(license, "/admin", {}), SkillRelayRequestError);
  await assert.rejects(relay.execute(license, "/skills", {geheim: "x"}), SkillRelayRequestError);
  await assert.rejects(rejecting.execute(license, "/skills", {}), /Lizenz/);

  assert.deepEqual(taken, ["lizenz-1"], "failed attempts cost nothing");
  assert.equal(calls.length, 1);
});

test("an empty bucket answers with the wait time and never reaches the upstream", async () => {
  const calls: string[] = [];
  const limiter: RateLimiter = {take: async () => ({allowed: false, retryAfterSeconds: 3})};
  const relay = relayWith(async () => ({licenseId: "l"}) as RuntimeLicense, calls, limiter);

  await assert.rejects(relay.execute(license, "/skills", {}), (error: unknown) =>
    error instanceof SkillRelayRateLimitedError && error.retryAfterSeconds === 3 && /3 Sekunden/.test(error.message));
  assert.deepEqual(calls, []);
});

test("the HMAC covers timestamp, method and path with query", () => {
  const signature = signSkillsRelayRequest("geheim", 1000, "get", "/api/relay?p=%2Fskills&q=a");

  assert.match(signature, /^[0-9a-f]{64}$/);
  assert.equal(signature, signSkillsRelayRequest("geheim", 1000, "GET", "/api/relay?p=%2Fskills&q=a"));
  for (const changed of [
    signSkillsRelayRequest("anderes", 1000, "GET", "/api/relay?p=%2Fskills&q=a"),
    signSkillsRelayRequest("geheim", 1001, "GET", "/api/relay?p=%2Fskills&q=a"),
    signSkillsRelayRequest("geheim", 1000, "POST", "/api/relay?p=%2Fskills&q=a"),
    signSkillsRelayRequest("geheim", 1000, "GET", "/api/relay?p=%2Fskills&q=b"),
  ]) assert.notEqual(changed, signature);
});

test("the signature matches the shared test vector of the Vercel proxy", () => {
  assert.equal(
    signSkillsRelayRequest("geheim", 1000, "get", "/api/relay?p=%2Fskills%2Fsearch&q=a"),
    "bbc2548f9c30d647cd144e35b718c50289966e3208055d96c99e2455e6f11b62",
  );
});

test("a signature is valid only inside the time window and for the exact request", () => {
  const now = 1_000_000;
  const signature = signSkillsRelayRequest("geheim", now, "GET", "/api/relay?p=%2Fskills");
  const valid = (offset: number, secret = "geheim", path = "/api/relay?p=%2Fskills", given = signature) =>
    isValidSkillsRelaySignature(secret, now, "GET", path, given, now + offset);

  assert.equal(valid(0), true);
  assert.equal(valid(signatureWindowMilliseconds), true);
  assert.equal(valid(signatureWindowMilliseconds + 1), false);
  assert.equal(valid(-signatureWindowMilliseconds - 1), false);
  assert.equal(valid(0, "falsch"), false);
  assert.equal(valid(0, "geheim", "/api/relay?p=%2Fskills%2Fsearch"), false);
  assert.equal(valid(0, "geheim", "/api/relay?p=%2Fskills", "abc"), false);
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

  const response = await upstream.get({path: "/skills/search", query: {q: "a"}});

  assert.equal(sent!.url, "https://proxy.example/api/relay?p=%2Fskills%2Fsearch&q=a");
  assert.equal(sent!.headers[timestampHeader], "5000");
  assert.equal(sent!.headers[signatureHeader], signSkillsRelayRequest("geheim", 5000, "GET", "/api/relay?p=%2Fskills%2Fsearch&q=a"));
  assert.equal(response.status, 429);
  assert.equal(response.body, "{\"x\":1}");
  assert.equal(response.headers["retry-after"], "7");
  assert.equal(response.headers["x-ratelimit-remaining"], "0");
  assert.equal(response.headers["set-cookie"], undefined);
});
