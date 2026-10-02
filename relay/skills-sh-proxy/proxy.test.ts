import assert from "node:assert/strict";
import test from "node:test";
import {isValidSignature, sign, signatureWindowMilliseconds, upstreamUrlFor} from "./proxy.ts";

test("only read-only catalog paths are forwarded, with the remaining parameters", () => {
  assert.equal(upstreamUrlFor("/api/relay?p=%2Fskills%2Fsearch&q=react"), "https://skills.sh/api/v1/skills/search?q=react");
  assert.equal(upstreamUrlFor("/api/relay?p=%2Fskills"), "https://skills.sh/api/v1/skills");
  assert.equal(upstreamUrlFor("/api/relay?p=/skills/vercel-labs/skills/find-skills"), "https://skills.sh/api/v1/skills/vercel-labs/skills/find-skills");
  assert.equal(upstreamUrlFor("/api/relay?p=%2Fskills%2Faudit%2Fa%2Fb%2Fc"), "https://skills.sh/api/v1/skills/audit/a/b/c");
  assert.equal(upstreamUrlFor("/api/relay?q=a+b&p=%2Fskills%2Fsearch&limit=5"), "https://skills.sh/api/v1/skills/search?q=a+b&limit=5");
});

test("other addresses, other paths and traversal attempts are rejected", () => {
  for (const url of [
    "/api/v1/skills/search", "/api/relay", "/api/relay?p=", "/api/relay?p=%2Fadmin", "/api/relay?p=%2Fskillsx",
    "/api/relay?p=%2Fskills%2F..%2Fadmin", "/api/relay?p=%2Fskills%2F%2Fx", "/api/relay?p=%2Fskills%5Ca", "/api/other?p=%2Fskills", "/",
  ]) {
    assert.equal(upstreamUrlFor(url), null, url);
  }
});

const vector = "bbc2548f9c30d647cd144e35b718c50289966e3208055d96c99e2455e6f11b62";

test("the signature matches the shared test vector of the Firebase function", () => {
  assert.equal(sign("geheim", 1000, "get", "/api/relay?p=%2Fskills%2Fsearch&q=a"), vector);
});

test("a request is valid only with exact signature and inside the time window", () => {
  const headers = {timestamp: "1000", signature: vector};
  const valid = (override = {}, secret: string | undefined = "geheim", path = "/api/relay?p=%2Fskills%2Fsearch&q=a", now = 1000) =>
    isValidSignature(secret, {...headers, ...override}, "GET", path, now);

  assert.equal(valid(), true);
  assert.equal(valid({}, "geheim", "/api/relay?p=%2Fskills%2Fsearch&q=a", 1000 + signatureWindowMilliseconds), true);
  assert.equal(valid({}, "geheim", "/api/relay?p=%2Fskills%2Fsearch&q=a", 1000 + signatureWindowMilliseconds + 1), false);
  assert.equal(valid({}, "geheim", "/api/relay?p=%2Fskills%2Fsearch&q=a", 1000 - signatureWindowMilliseconds - 1), false);
  assert.equal(valid({}, "falsch"), false);
  assert.equal(valid({}, "geheim", "/api/relay?p=%2Fskills%2Fsearch&q=b"), false);
  assert.equal(valid({signature: vector.replace(/.$/, "0")}), false);
  assert.equal(valid({signature: "kurz"}), false);
  assert.equal(valid({timestamp: "kein-wert"}), false);
  assert.equal(valid({timestamp: undefined}), false);
  assert.equal(valid({signature: undefined}), false);
  assert.equal(isValidSignature(undefined, headers, "GET", "/api/relay?p=%2Fskills%2Fsearch&q=a", 1000), false);
  assert.equal(valid({}, ""), false);
});
