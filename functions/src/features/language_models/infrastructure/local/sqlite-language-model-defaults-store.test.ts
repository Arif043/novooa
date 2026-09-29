import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {SQLiteLanguageModelDefaultsStore} from "./sqlite-language-model-defaults-store.js";

test("liefert leere Vorgaben, solange nichts gespeichert wurde", async () => {
  await withStore(async (store) => {
    const defaults = await store.loadDefaults("team-1");

    assert.deepEqual(defaults, {blockModelId: null, assistantModelId: null});
  });
});

test("speichert und liest beide Vorgaben", async () => {
  await withStore(async (store) => {
    await store.saveDefaults("team-1", {
      blockModelId: "model-1",
      assistantModelId: "model-2",
    });

    const defaults = await store.loadDefaults("team-1");

    assert.deepEqual(defaults, {blockModelId: "model-1", assistantModelId: "model-2"});
  });
});

test("ein erneutes Speichern überschreibt statt eine zweite Zeile anzulegen", async () => {
  await withStore(async (store) => {
    await store.saveDefaults("team-1", {blockModelId: "model-1", assistantModelId: null});
    await store.saveDefaults("team-1", {blockModelId: "model-2", assistantModelId: "model-3"});

    const defaults = await store.loadDefaults("team-1");

    assert.deepEqual(defaults, {blockModelId: "model-2", assistantModelId: "model-3"});
  });
});

test("hält Vorgaben verschiedener Teams getrennt", async () => {
  await withStore(async (store) => {
    await store.saveDefaults("team-1", {blockModelId: "model-1", assistantModelId: null});
    await store.saveDefaults("team-2", {blockModelId: "model-2", assistantModelId: null});

    assert.equal((await store.loadDefaults("team-1")).blockModelId, "model-1");
    assert.equal((await store.loadDefaults("team-2")).blockModelId, "model-2");
  });
});

async function withStore(
  operation: (store: SQLiteLanguageModelDefaultsStore) => Promise<void>,
): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-language-model-defaults-"));
  const database = await openLocalRuntimeDatabase({
    databasePath: join(directory, "novooa.sqlite"),
    migrationsDirectory,
  });
  try {
    await operation(new SQLiteLanguageModelDefaultsStore(database));
  } finally {
    database.close();
    await rm(directory, {force: true, recursive: true});
  }
}

const migrationsDirectory = resolve(__dirname, "../../../../../../local-runtime/migrations");
