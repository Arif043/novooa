import assert from "node:assert/strict";
import test from "node:test";
import {isAuthorized, upstreamUrlFor} from "./proxy.ts";

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

test("the access key must match exactly", () => {
  assert.equal(isAuthorized("Bearer geheim", "geheim"), true);
  assert.equal(isAuthorized("Bearer falsch", "geheim"), false);
  assert.equal(isAuthorized("Bearer geheim-und-mehr", "geheim"), false);
  assert.equal(isAuthorized("geheim", "geheim"), false);
  assert.equal(isAuthorized(undefined, "geheim"), false);
  assert.equal(isAuthorized("Bearer x", undefined), false);
  assert.equal(isAuthorized("Bearer ", ""), false);
});
