import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {readFile} from "node:fs/promises";
import {RotateRuntimeMasterKeyIfDue, nextRotationAt} from "../domain/usecases/rotate-runtime-master-key-if-due.js";
import {RotateRuntimeMasterKey} from "../domain/usecases/rotate-runtime-master-key.js";
import {FileRuntimeKeyRepository} from "./file-runtime-key-repository.js";
import {LocalRuntimeSecretRotationStore} from "./local-runtime-secret-rotation-store.js";
import {CurrentRuntimeFieldCipher} from "./current-runtime-field-cipher.js";
import {AutomaticRuntimeKeyRotation} from "./automatic-runtime-key-rotation.js";
import {parseRuntimeKeyring} from "./runtime-keyring.js";
import {rotationFixture} from "./runtime-rotation-test-fixture.js";
import {writeDurableSecretFile} from "./durable-secret-file.js";

test("uses calendar months and clamps month ends, retaining the UTC time", () => {
  assert.equal(nextRotationAt(new Date("2026-01-31T12:34:56Z")).toISOString(), "2026-02-28T12:34:56.000Z");
  assert.equal(nextRotationAt(new Date("2028-01-31T12:34:56Z")).toISOString(), "2028-02-29T12:34:56.000Z");
  assert.equal(nextRotationAt(new Date("2026-12-15T12:34:56Z")).toISOString(), "2027-01-15T12:34:56.000Z");
});

test("rotates once when due and persists the next deadline across restarts", async () => {
  const fixture = await scheduledFixture();
  try {
    const before = await readFile(fixture.keyFile, "utf8");
    const first = await fixture.workflow.execute();
    assert.equal(first.rotatedSecrets, 3);
    assert.equal(first.nextCheckAt.toISOString(), "2026-03-28T10:00:00.000Z");
    assert.notEqual(await readFile(fixture.keyFile, "utf8"), before);
    const completed = await readFile(fixture.keyFile, "utf8");
    assert.equal((await fixture.workflow.execute()).rotatedSecrets, null);
    assert.equal(await readFile(fixture.keyFile, "utf8"), completed);
    assert.equal(Object.keys(parseRuntimeKeyring(completed).keys).length, 2);
    assert.equal(fixture.current.decrypt(fixture.current.encrypt("new", ["field"]), ["field"]), "new");
  } finally {
    await fixture.cleanup();
  }
});

test("does not rotate early and catches up after downtime without generating missed monthly keys", async () => {
  const fixture = await scheduledFixture();
  try {
    fixture.clock.value = new Date("2026-02-27T10:00:00Z");
    assert.equal((await fixture.workflow.execute()).rotatedSecrets, null);
    fixture.clock.value = new Date("2026-08-15T10:00:00Z");
    assert.equal((await fixture.workflow.execute()).rotatedSecrets, 3);
    const completed = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(Object.keys(completed.keys).length, 2);
    assert.equal(completed.lastRotatedAt, "2026-08-15T10:00:00.000Z");
  } finally {
    await fixture.cleanup();
  }
});

test("automatically resumes a pending rotation even before the next monthly deadline", async () => {
  const fixture = await scheduledFixture();
  try {
    fixture.clock.value = new Date("2026-02-01T10:00:00Z");
    await fixture.keys.beginRotation();
    const staged = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal((await fixture.workflow.execute()).rotatedSecrets, 3);
    const completed = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
    assert.equal(completed.activeKeyId, staged.activeKeyId);
    assert.equal(completed.rotationPending, false);
  } finally {
    await fixture.cleanup();
  }
});

test("worker schedules short timers, prevents duplicate starts and cancels on shutdown", async () => {
  const fixture = await scheduledFixture();
  const timers: {callback: () => void; delay: number; cancelled: boolean}[] = [];
  const worker = new AutomaticRuntimeKeyRotation(fixture.workflow, (callback, delay) => {
    const timer = {callback, delay, cancelled: false};
    timers.push(timer);
    return {cancel: () => { timer.cancelled = true; }};
  }, () => {}, () => fixture.clock.value);
  try {
    fixture.clock.value = new Date("2026-02-27T10:00:00Z");
    worker.start(); worker.start();
    await settleUntil(() => timers.length === 1);
    assert.equal(timers[0].delay, 24 * 60 * 60 * 1000);
    await worker.stop();
    assert.equal(timers[0].cancelled, true);
  } finally {
    await worker.stop(); await fixture.cleanup();
  }
});

test("worker retains pending rotation and retries failures after five minutes", async () => {
  const fixture = await scheduledFixture();
  const events: string[] = [];
  let retryDelay = 0;
  const worker = new AutomaticRuntimeKeyRotation(fixture.workflow, (_callback, delay) => {
    retryDelay = delay;
    return {cancel: () => {}};
  }, (event) => { events.push(event); }, () => fixture.clock.value);
  try {
    await fixture.database.run(sql`UPDATE language_model_secrets SET encrypted_value = 'corrupt'`);
    worker.start(); await settleUntil(() => retryDelay > 0); await worker.stop();
    assert.equal(retryDelay, 5 * 60 * 1000);
    assert.deepEqual(events, ["local_runtime.master_key_rotation_failed"]);
    assert.equal(parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8")).rotationPending, true);
  } finally {
    await worker.stop(); await fixture.cleanup();
  }
});

async function scheduledFixture() {
  const fixture = await rotationFixture();
  const keyring = parseRuntimeKeyring(await readFile(fixture.keyFile, "utf8"));
  keyring.lastRotatedAt = "2026-01-31T10:00:00.000Z";
  await writeDurableSecretFile(fixture.keyFile, JSON.stringify(keyring));
  const current = new CurrentRuntimeFieldCipher(JSON.stringify(keyring));
  const clock = {value: new Date("2026-02-28T10:00:00Z")};
  const keys = new FileRuntimeKeyRepository(fixture.keyFile, (value) => current.update(value), () => clock.value);
  const secrets = new LocalRuntimeSecretRotationStore(fixture.database, fixture.root);
  const workflow = new RotateRuntimeMasterKeyIfDue(keys, new RotateRuntimeMasterKey(keys, secrets), () => clock.value);
  return {...fixture, current, clock, keys, workflow};
}

async function settleUntil(condition: () => boolean): Promise<void> {
  for (let attempt = 0; attempt < 1000 && !condition(); attempt++) {
    await new Promise<void>((resolve) => setTimeout(resolve, 1));
  }
  assert.ok(condition(), "Worker did not complete in time");
}
