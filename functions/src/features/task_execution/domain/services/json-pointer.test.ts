import assert from "node:assert/strict";
import test from "node:test";
import {valueAtJsonPointer} from "./json-pointer.js";

test("resolves RFC-6901 object keys and array entries", () => {
  const value = {items: [{"a/b": {"~key": "ok"}}]};

  assert.equal(valueAtJsonPointer(value, "/items/0/a~1b/~0key"), "ok");
});

test("returns undefined for an unknown JSON pointer", () => {
  assert.equal(valueAtJsonPointer({items: []}, "/items/0"), undefined);
});
