import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {initializeRuntimeKeyring} from "./initialize-runtime-keyring.js";

test("creates a random keyring on the first start and keeps it on later starts", async () => {
  const root = await mkdtemp(join(tmpdir(), "novooa-key-init-"));
  const destination = join(root, "keyring");
  try {
    assert.equal(await initializeRuntimeKeyring(destination), true);
    const initial = await readFile(destination, "utf8");
    assert.equal(Object.keys(parseRuntimeKeyring(initial).keys).length, 1);

    assert.equal(await initializeRuntimeKeyring(destination), false);
    assert.equal(await readFile(destination, "utf8"), initial);
  } finally { await rm(root, {recursive: true, force: true}); }
});

test("keyring parser errors never disclose input key material", () => {
  const marker = "sensitive-key-marker";
  assert.throws(() => parseRuntimeKeyring(marker), (error: unknown) => {
    assert.ok(error instanceof Error);
    assert.doesNotMatch(error.message, /sensitive|marker/);
    return true;
  });
});

test("concurrent initialization publishes exactly one complete valid keyring", async () => {
  const root = await mkdtemp(join(tmpdir(), "novooa-key-init-"));
  const destination = join(root, "keyring");
  try {
    const created = await Promise.all([initializeRuntimeKeyring(destination), initializeRuntimeKeyring(destination)]);
    assert.equal(created.filter(Boolean).length, 1);
    assert.equal(parseRuntimeKeyring(await readFile(destination, "utf8")).rotationPending, false);
  } finally { await rm(root, {recursive: true, force: true}); }
});
