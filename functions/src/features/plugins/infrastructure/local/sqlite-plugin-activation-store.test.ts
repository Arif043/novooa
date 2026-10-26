import assert from "node:assert/strict";
import test from "node:test";
import {teams} from "../../../../db/schema.js";
import {testRuntimeWorkspace, withRuntimeTestDatabase} from "../../../../shared/local/local-runtime-test-database.js";
import {ListPlugins, SetPluginEnabled} from "../../domain/usecases/plugin-usecases.js";
import {SQLitePluginActivationStore} from "./sqlite-plugin-activation-store.js";

const team = testRuntimeWorkspace.teamId;
const catalog = ["shopware", "googleDrive"];

test("plugins are off by default and switch per workspace", () => withRuntimeTestDatabase(async (database) => {
  await database.insert(teams).values({id: "anderes-team", name: "Anderes", owner_uid: testRuntimeWorkspace.userId});
  const store = new SQLitePluginActivationStore(database, () => new Date("2026-10-26T10:00:00.000Z"));
  const setEnabled = new SetPluginEnabled(catalog, store);

  assert.equal(await store.isEnabled(team, "googleDrive"), false);
  await setEnabled.execute({teamId: team, pluginId: "googleDrive", enabled: true, uid: "admin"});
  await setEnabled.execute({teamId: team, pluginId: "googleDrive", enabled: true, uid: "admin"});

  assert.equal(await store.isEnabled(team, "googleDrive"), true);
  assert.equal(await store.isEnabled("anderes-team", "googleDrive"), false);
  assert.deepEqual(await new ListPlugins(catalog, store).execute(team), [
    {id: "shopware", enabled: false, enabledAt: null},
    {id: "googleDrive", enabled: true, enabledAt: "2026-10-26T10:00:00.000Z"},
  ]);

  const disabled = await setEnabled.execute({teamId: team, pluginId: "googleDrive", enabled: false, uid: "admin"});
  assert.deepEqual(disabled, {id: "googleDrive", enabled: false, enabledAt: null});
  assert.equal(await store.isEnabled(team, "googleDrive"), false);
}));

test("only plugins of the catalog can be switched", () => withRuntimeTestDatabase(async (database) => {
  const setEnabled = new SetPluginEnabled(catalog, new SQLitePluginActivationStore(database));

  await assert.rejects(
    setEnabled.execute({teamId: team, pluginId: "fremd", enabled: true, uid: "admin"}),
    (error: unknown) => error instanceof Error && "code" in error && error.code === "plugin_not_found",
  );
}));
