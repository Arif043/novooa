import assert from "node:assert/strict";
import test from "node:test";
import {AccessTokenCache} from "./access-token-cache.js";

test("liefert ein Token bis kurz vor dem Ablauf", () => {
  const cache = new AccessTokenCache(60_000);
  cache.set("c1", "token", 1_000_000);

  assert.equal(cache.get("c1", 900_000), "token");
  assert.equal(cache.get("c1", 940_001), null, "innerhalb der Sicherheitsspanne");
  assert.equal(cache.get("c1", 900_000), null, "abgelaufene Einträge sind entfernt");
});

test("kennt Connectoren getrennt und vergisst auf Wunsch", () => {
  const cache = new AccessTokenCache();
  cache.set("c1", "a", Date.now() + 3_600_000);
  cache.set("c2", "b", Date.now() + 3_600_000);

  cache.delete("c1");

  assert.equal(cache.get("c1", Date.now()), null);
  assert.equal(cache.get("c2", Date.now()), "b");
});

test("begrenzt die Zahl der Einträge und verwirft die ältesten", () => {
  const cache = new AccessTokenCache(0, 2);
  for (const id of ["a", "b", "c"]) cache.set(id, id, Date.now() + 3_600_000);

  assert.equal(cache.get("a", Date.now()), null);
  assert.equal(cache.get("b", Date.now()), "b");
  assert.equal(cache.get("c", Date.now()), "c");
});
