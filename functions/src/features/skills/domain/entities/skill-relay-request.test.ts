import assert from "node:assert/strict";
import test from "node:test";
import {pathAndQueryOf, skillRelayRequestFrom, SkillRelayRequestError} from "./skill-relay-request.js";

test("read-only catalog paths and known parameters are accepted", () => {
  for (const path of ["/skills", "/skills/search", "/skills/curated", "/skills/vercel-labs/skills/find-skills", "/skills/audit/a/b/c", "/skills/a/b/find%20skills"]) {
    assert.equal(skillRelayRequestFrom(path, {}).path, path, path);
  }
  const request = skillRelayRequestFrom("/skills/search", {q: "react native", limit: "10"});
  assert.equal(pathAndQueryOf(request), "/api/v1/skills/search?q=react+native&limit=10");
  assert.equal(pathAndQueryOf(skillRelayRequestFrom("/skills", undefined)), "/api/v1/skills");
});

test("other paths, traversal and encoded separators are rejected", () => {
  for (const path of [
    "/admin", "/skillsx", "skills", "/skills/../admin", "/skills/%2e%2e/x", "/skills/%2E%2E", "/skills/a%2Fb", "/skills/a%5Cb",
    "/skills//x", "/skills/a b", "/skills/a?x=1", "/skills/%00", "/skills/%zz", 42, null, undefined, `/skills/${"a".repeat(300)}`,
    "/skills/1/2/3/4/5/6/7/8",
  ]) {
    assert.throws(() => skillRelayRequestFrom(path, {}), SkillRelayRequestError, String(path));
  }
});

test("unknown or malformed parameters are rejected", () => {
  assert.throws(() => skillRelayRequestFrom("/skills", {token: "x"}), /nicht weitergegeben/);
  assert.throws(() => skillRelayRequestFrom("/skills", {q: 5}), /ungültig/);
  assert.throws(() => skillRelayRequestFrom("/skills", {q: "x".repeat(201)}), /ungültig/);
  assert.throws(() => skillRelayRequestFrom("/skills", ["q"]), SkillRelayRequestError);
});
