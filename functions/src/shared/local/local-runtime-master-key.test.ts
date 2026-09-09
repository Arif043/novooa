import assert from "node:assert/strict";
import {mkdtemp, readFile} from "node:fs/promises";
import test from "node:test";
import {join} from "node:path";
import {tmpdir} from "node:os";
import {
  localRuntimeMasterKeyFrom,
  prepareLocalRuntimeMasterKey,
} from "./local-runtime-master-key.js";

test("creates one stable local runtime master key", async () => {
  const directory = await mkdtemp(join(tmpdir(), "novooa-master-key-"));
  const secretFile = join(directory, "secrets", "runtime-master-key");

  assert.equal(await prepareLocalRuntimeMasterKey(secretFile), true);
  const firstKey = await localRuntimeMasterKeyFrom(secretFile);
  assert.equal(Buffer.from(firstKey, "base64").length, 32);

  assert.equal(await prepareLocalRuntimeMasterKey(secretFile), false);
  assert.equal(await localRuntimeMasterKeyFrom(secretFile), firstKey);
  assert.equal((await readFile(secretFile, "utf8")).trim(), firstKey);
});
