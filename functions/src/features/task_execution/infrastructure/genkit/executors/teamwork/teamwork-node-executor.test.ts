import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {createTeamworkNodeExecutor} from "./teamwork-node-executor.js";

const logger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

function node(config: Record<string, unknown>) {
  return {id: "t", primitive: "teamwork", title: "Team", description: "",
    config: {primitive: "teamwork", instruction: "Los", members: [], outputFields: [], attachments: [], knowledgeAttachments: [], ...config}} as never;
}

test("without members or result fields the block names the missing setting", async () => {
  const executor = createTeamworkNodeExecutor({ai: genkit({}), logger});

  const noMembers = (await executor.execute(node({outputFields: [{name: "a", type: "string", description: ""}]}), {} as never))._unsafeUnwrapErr();
  const noFields = (await executor.execute(node({members: [{employeeId: "e", responsibility: "x"}], outputFields: [{name: " ", type: "string", description: ""}]}), {} as never))._unsafeUnwrapErr();

  assert.deepEqual([noMembers.code, noMembers.details], ["settingMissing", {setting: "teamMembers"}]);
  assert.deepEqual([noFields.code, noFields.details], ["settingMissing", {setting: "resultFields"}]);
});
