import assert from "node:assert/strict";
import test from "node:test";
import {isValidSignature, sign, signatureWindowMilliseconds, upstreamUrlFor} from "./proxy.ts";

test("only read-only catalog paths are forwarded, with their query", () => {
  assert.equal(upstreamUrlFor("/api/v1/skills/search?q=react"), "https://skills.sh/api/v1/skills/search?q=react");
  assert.equal(upstreamUrlFor("/api/v1/skills"), "https://skills.sh/api/v1/skills");
  assert.equal(upstreamUrlFor("/api/v1/skills/vercel-labs/skills/find-skills"), "https://skills.sh/api/v1/skills/vercel-labs/skills/find-skills");
  assert.equal(upstreamUrlFor("/api/v1/skills/audit/a/b/c"), "https://skills.sh/api/v1/skills/audit/a/b/c");
});

test("other paths and traversal attempts are rejected", () => {
  for (const url of ["/api/v1/admin", "/api/v1/skillsx", "/api/v1/skills/../admin", "/api/v1/skills//x", "/api/v1/skills/a%5Cb", "/"]) {
    const result = upstreamUrlFor(url);
    assert.ok(result === null || !result.includes(".."), url);
  }
  assert.equal(upstreamUrlFor("/api/v1/admin"), null);
  assert.equal(upstreamUrlFor("/api/v1/skillsx"), null);
  // Punktsegmente löst die URL-Normalisierung auf, bevor der Pfad geprüft wird; nach außen führt das nie.
  assert.equal(upstreamUrlFor("/api/v1/skills/a/../b"), "https://skills.sh/api/v1/skills/b");
  assert.equal(upstreamUrlFor("/api/v1/skills/../../admin"), null);
  assert.equal(upstreamUrlFor("/api/v1/skills//x"), null);
  assert.equal(upstreamUrlFor("/"), null);
});

const vector = "f09c1c1f90def0417b5dd51ac394c93458fce17ab25c5d25fec109199e78f43b";

test("the signature matches the shared test vector of the Firebase function", () => {
  assert.equal(sign("geheim", 1000, "get", "/api/v1/skills/search?q=a"), vector);
});

test("a request is valid only with exact signature and inside the time window", () => {
  const headers = {timestamp: "1000", signature: vector};
  const valid = (override = {}, secret: string | undefined = "geheim", path = "/api/v1/skills/search?q=a", now = 1000) =>
    isValidSignature(secret, {...headers, ...override}, "GET", path, now);

  assert.equal(valid(), true);
  assert.equal(valid({}, "geheim", "/api/v1/skills/search?q=a", 1000 + signatureWindowMilliseconds), true);
  assert.equal(valid({}, "geheim", "/api/v1/skills/search?q=a", 1000 + signatureWindowMilliseconds + 1), false);
  assert.equal(valid({}, "geheim", "/api/v1/skills/search?q=a", 1000 - signatureWindowMilliseconds - 1), false);
  assert.equal(valid({}, "falsch"), false);
  assert.equal(valid({}, "geheim", "/api/v1/skills/search?q=b"), false);
  assert.equal(valid({signature: vector.replace(/.$/, "0")}), false);
  assert.equal(valid({signature: "kurz"}), false);
  assert.equal(valid({timestamp: "kein-wert"}), false);
  assert.equal(valid({timestamp: undefined}), false);
  assert.equal(valid({signature: undefined}), false);
  assert.equal(isValidSignature(undefined, headers, "GET", "/api/v1/skills/search?q=a", 1000), false);
  assert.equal(valid({}, ""), false);
});
