import assert from "node:assert/strict";
import test from "node:test";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {scriptPackageRoutes} from "./local-script-package-routes.js";
import {type ScriptPackageJobs} from "./script-package-jobs.js";

test("starts an installation and reports the environments", async () => {
  const started: string[][] = [];
  const jobs = {
    start: (packages: readonly string[]) => {
      started.push([...packages]);
      return ["six"];
    },
    list: async () => [{packages: ["six"], state: "installing"}],
  } as unknown as ScriptPackageJobs;
  const {handle} = testingRoutes(scriptPackageRoutes, {jobs});

  const install = await handle({method: "POST", url: "/v1/script-packages", body: {packages: ["Six"]}});
  const list = await handle({method: "GET", url: "/v1/script-packages", body: undefined});

  assert.deepEqual(install, {statusCode: 202, body: {packages: ["six"], state: "installing"}});
  assert.deepEqual(started, [["Six"]]);
  assert.deepEqual(list?.body, {items: [{packages: ["six"], state: "installing"}]});
});

test("without the package service the routes answer 503", async () => {
  const {handle} = testingRoutes(scriptPackageRoutes, {jobs: undefined});

  const response = await handle({method: "POST", url: "/v1/script-packages", body: {packages: ["six"]}});

  assert.equal(response?.statusCode, 503);
});
