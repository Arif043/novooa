import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join} from "node:path";
import test from "node:test";
import {acquireLocalRuntimeProcessLock} from "./local-runtime-process-lock.js";

test("prevents runtime and rotation from accessing the same data concurrently", async () => {
  const root = await mkdtemp(join(tmpdir(), "novooa-process-lock-"));
  const release = await acquireLocalRuntimeProcessLock(root);
  try {
    await assert.rejects(acquireLocalRuntimeProcessLock(root), /Runtime.*stoppen/);
  } finally {
    await release();
  }
  const releaseNext = await acquireLocalRuntimeProcessLock(root);
  await releaseNext();
  await rm(root, {recursive: true, force: true});
});
