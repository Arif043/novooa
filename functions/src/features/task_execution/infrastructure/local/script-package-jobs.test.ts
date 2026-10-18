import assert from "node:assert/strict";
import test from "node:test";
import {err, ok} from "neverthrow";
import {type InstalledScriptPackageEnvironment} from "../../domain/repositories/script-package-installer.js";
import {scriptPackageEnvironmentId} from "./script-package-environment-id.js";
import {ScriptPackageJobs} from "./script-package-jobs.js";

const logger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

function installerWith(installed: InstalledScriptPackageEnvironment[], failInstall = false) {
  const removed: string[] = [];
  const installs: string[][] = [];
  let release: () => void = () => undefined;
  const gate = new Promise<void>((resolve) => { release = resolve; });
  return {
    removed, installs, release, gate,
    async list() {
      return installed;
    },
    async install(id: string, packages: readonly string[]) {
      installs.push([...packages]);
      await gate;
      if (failInstall) return err({reason: "notFound" as const, detail: "gibtsnicht"});
      const environment = {id, packages: [...packages], sizeBytes: 10};
      installed.push(environment);
      return ok(environment);
    },
    async remove(id: string) {
      removed.push(id);
    },
  };
}

const settle = () => new Promise((resolve) => setImmediate(resolve));

test("installs a normalized list once, reports progress and then lists it as ready", async () => {
  const installer = installerWith([]);
  const topics: string[] = [];
  const jobs = new ScriptPackageJobs(installer, async () => [["six"]], {publish: (topic) => topics.push(topic)}, logger);

  assert.deepEqual(jobs.start(["Six"]), ["six"]);
  jobs.start(["six"]);
  assert.deepEqual(await jobs.list(), [{packages: ["six"], state: "installing"}]);
  installer.release();
  await settle();

  assert.deepEqual(installer.installs, [["six"]]);
  assert.deepEqual(await jobs.list(), [{packages: ["six"], state: "ready", sizeBytes: 10}]);
  assert.ok(topics.length >= 2);
});

test("a failed installation keeps its reason until the next attempt", async () => {
  const installer = installerWith([], true);
  const jobs = new ScriptPackageJobs(installer, async () => [], {publish() {}}, logger);

  jobs.start(["gibtsnicht"]);
  installer.release();
  await settle();

  assert.deepEqual(await jobs.list(), [{packages: ["gibtsnicht"], state: "failed", reason: "notFound", detail: "gibtsnicht"}]);
});

test("removes environments that no script uses any more", async () => {
  const used = {id: scriptPackageEnvironmentId(["six"]), packages: ["six"], sizeBytes: 1};
  const unused = {id: scriptPackageEnvironmentId(["numpy"]), packages: ["numpy"], sizeBytes: 1};
  const installer = installerWith([used, unused]);
  const jobs = new ScriptPackageJobs(installer, async () => [["six"]], {publish() {}}, logger);

  await jobs.removeUnused();

  assert.deepEqual(installer.removed, [unused.id]);
});
