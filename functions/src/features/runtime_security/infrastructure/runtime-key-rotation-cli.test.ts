import assert from "node:assert/strict";
import {execFile} from "node:child_process";
import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import test from "node:test";
import {promisify} from "node:util";
import {rotationFixture} from "./runtime-rotation-test-fixture.js";
import {FileRuntimeKeyRepository} from "./file-runtime-key-repository.js";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {acquireLocalRuntimeProcessLock} from "../../../shared/local/local-runtime-process-lock.js";

const executeFile = promisify(execFile);
const cli = resolve(__dirname, "../../../shared/local/local-runtime-key-rotation-cli.js");

test("the maintenance CLI rotates persisted secrets and retires old keys on request", async () => {
  const fixture = await rotationFixture();
  try {
    const {stdout} = await executeFile(process.execPath, [cli, "--runtime-root", fixture.root,
      "--secret-file", fixture.keyFile, "--retire-old-keys"]);
    assert.match(stdout, /3 Datenschlüssel/);
    const keyring = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(keyring.rotationPending, false);
    assert.equal(Object.keys(keyring.keys).length, 1);
  } finally {
    await fixture.cleanup();
  }
});

test("the maintenance CLI fails before changing keys while the runtime lock is held", async () => {
  const fixture = await rotationFixture();
  const release = await acquireLocalRuntimeProcessLock(fixture.root);
  try {
    const before = await readFile(fixture.keyFile, "utf8");
    await assert.rejects(executeFile(process.execPath, [cli, "--runtime-root", fixture.root,
      "--secret-file", fixture.keyFile]), /Runtime.*stoppen/);
    assert.equal(await readFile(fixture.keyFile, "utf8"), before);
  } finally {
    await release();
    await fixture.cleanup();
  }
});

test("the maintenance CLI resumes a staged rotation instead of generating another key", async () => {
  const fixture = await rotationFixture();
  try {
    await new FileRuntimeKeyRepository(fixture.keyFile).beginRotation();
    const staged = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    await executeFile(process.execPath, [cli, "--runtime-root", fixture.root, "--secret-file", fixture.keyFile]);
    const completed = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(completed.activeKeyId, staged.activeKeyId);
    assert.equal(Object.keys(completed.keys).length, 2);
    assert.equal(completed.rotationPending, false);
  } finally {
    await fixture.cleanup();
  }
});
