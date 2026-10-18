import assert from "node:assert/strict";
import test from "node:test";
import {err, ok, type Result} from "neverthrow";
import {
  type InstalledScriptPackageEnvironment,
  type ScriptPackageInstallFailure,
} from "../../domain/repositories/script-package-installer.js";
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

const loadable = {check: async () => ok(undefined)};

function probeWith(verdict: () => Promise<Result<void, ScriptPackageInstallFailure>>) {
  let release: () => void = () => undefined;
  const gate = new Promise<void>((resolve) => { release = resolve; });
  return {release, check: async () => { await gate; return verdict(); }};
}

const settle = () => new Promise((resolve) => setImmediate(resolve));

test("installs a normalized list once, reports progress and then lists it as ready", async () => {
  const installer = installerWith([]);
  const topics: string[] = [];
  const jobs = new ScriptPackageJobs(installer, loadable, async () => [["six"]], {publish: (topic) => topics.push(topic)}, logger);

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
  const jobs = new ScriptPackageJobs(installer, loadable, async () => [], {publish() {}}, logger);

  jobs.start(["gibtsnicht"]);
  installer.release();
  await settle();

  assert.deepEqual(await jobs.list(), [{packages: ["gibtsnicht"], state: "failed", reason: "notFound", detail: "gibtsnicht"}]);
});

test("removes environments that no script uses any more", async () => {
  const used = {id: scriptPackageEnvironmentId(["six"]), packages: ["six"], sizeBytes: 1};
  const unused = {id: scriptPackageEnvironmentId(["numpy"]), packages: ["numpy"], sizeBytes: 1};
  const installer = installerWith([used, unused]);
  const jobs = new ScriptPackageJobs(installer, loadable, async () => [["six"]], {publish() {}}, logger);

  await jobs.removeUnused();

  assert.deepEqual(installer.removed, [unused.id]);
});

test("an environment counts as ready only after the probe loaded it", async () => {
  const installer = installerWith([]);
  const probe = probeWith(async () => ok(undefined));
  const jobs = new ScriptPackageJobs(installer, probe, async () => [["six"]], {publish() {}}, logger);

  jobs.start(["six"]);
  installer.release();
  await settle();
  assert.deepEqual(await jobs.list(), [{packages: ["six"], state: "installing"}]);
  probe.release();
  await settle();

  assert.deepEqual(await jobs.list(), [{packages: ["six"], state: "ready", sizeBytes: 10}]);
});

test("removes an environment that cannot be loaded and reports why", async () => {
  const installer = installerWith([]);
  const probe = probeWith(async () => err({reason: "notLoadable" as const, detail: "weasyprint: OSError: libpango"}));
  const jobs = new ScriptPackageJobs(installer, probe, async () => [["weasyprint"]], {publish() {}}, logger);

  jobs.start(["weasyprint"]);
  installer.release();
  probe.release();
  await settle();

  assert.deepEqual(installer.removed, [scriptPackageEnvironmentId(["weasyprint"])]);
  assert.deepEqual((await jobs.list()).filter((status) => status.state !== "ready"), [{
    packages: ["weasyprint"], state: "failed", reason: "notLoadable", detail: "weasyprint: OSError: libpango",
  }]);
});

test("without an answer from the script service the environment is removed again", async () => {
  const installer = installerWith([]);
  const probe = probeWith(async () => { throw new Error("Der Script-Dienst ist nicht erreichbar."); });
  const jobs = new ScriptPackageJobs(installer, probe, async () => [["six"]], {publish() {}}, logger);

  jobs.start(["six"]);
  installer.release();
  probe.release();
  await settle();

  assert.deepEqual(installer.removed, [scriptPackageEnvironmentId(["six"])]);
  assert.equal((await jobs.list()).find((status) => status.state === "failed")?.reason, "failed");
});
