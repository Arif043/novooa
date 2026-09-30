import assert from "node:assert/strict";
import {mkdtemp, readFile, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {createRuntimeKeyring, parseRuntimeKeyring} from "./runtime-keyring.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";
import {seedRuntimeKeyring} from "./seed-runtime-keyring.js";

test("imports an existing Base64 setup key without replacing its key material", async () => {
  const root = await mkdtemp(join(tmpdir(), "novooa-legacy-seed-"));
  const source = join(root, "setup-key");
  const destination = join(root, "keys", "keyring");
  const existingKey = Buffer.alloc(32, 7).toString("base64");
  try {
    await writeDurableSecretFile(source, `${existingKey}\n`);
    await seedRuntimeKeyring(source, destination);
    const keyring = parseRuntimeKeyring(await readFile(destination, "utf8"));
    assert.equal(keyring.keys[keyring.activeKeyId], existingKey);
    assert.equal(Object.keys(keyring.keys).length, 1);
    assert.equal(await readFile(source, "utf8"), `${existingKey}\n`);
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

test("initializes a separate keyring without overwriting it on later starts", async () => {
  const root = await mkdtemp(join(tmpdir(), "novooa-key-seed-"));
  const source = join(root, "setup", "keyring");
  const destination = join(root, "keys", "keyring");
  try {
    await writeDurableSecretFile(source, JSON.stringify(createRuntimeKeyring()));
    await seedRuntimeKeyring(source, destination);
    const initial = await readFile(destination, "utf8");
    await writeDurableSecretFile(source, JSON.stringify(createRuntimeKeyring()));
    await seedRuntimeKeyring(source, destination);
    assert.equal(await readFile(destination, "utf8"), initial);
    await seedRuntimeKeyring(join(root, "missing-source"), destination);
    assert.equal(await readFile(destination, "utf8"), initial);
  } finally { await rm(root, {recursive: true, force: true}); }
});

test("concurrent initialization publishes exactly one complete valid keyring", async () => {
  const root = await mkdtemp(join(tmpdir(), "novooa-key-seed-"));
  const destination = join(root, "keys", "keyring");
  try {
    const first = JSON.stringify(createRuntimeKeyring());
    const second = JSON.stringify(createRuntimeKeyring());
    await writeDurableSecretFile(join(root, "first"), first);
    await writeDurableSecretFile(join(root, "second"), second);
    await Promise.all([seedRuntimeKeyring(join(root, "first"), destination), seedRuntimeKeyring(join(root, "second"), destination)]);
    const persisted = await readFile(destination, "utf8");
    assert.ok(persisted === first || persisted === second);
    assert.equal(parseRuntimeKeyring(persisted).rotationPending, false);
  } finally { await rm(root, {recursive: true, force: true}); }
});
