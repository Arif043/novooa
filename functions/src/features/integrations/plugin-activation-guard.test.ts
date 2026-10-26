import assert from "node:assert/strict";
import test from "node:test";
import {ok} from "neverthrow";
import {type NodeExecutor} from "../task_execution/domain/executors/node-executor.js";
import {type WebhookInterpreter} from "../webhooks/domain/entities/webhook-interpreter.js";
import {executorEnabledBy, interpreterEnabledBy} from "./plugin-activation-guard.js";

const executor: NodeExecutor = {primitive: "googleDrive", execute: async () => ok({ran: true} as never)};
const interpreter: WebhookInterpreter = {interpret: async () => [{context: "c", event: {}}]};
const enabledIn = (team: string) => ({isEnabled: async (teamId: string) => teamId === team});

test("a disabled plugin fails its blocks with pluginDisabled, an enabled one runs them", async () => {
  const guarded = executorEnabledBy("googleDrive", executor, enabledIn("team-1"));

  const disabled = await guarded.execute({} as never, {teamId: "team-2"} as never);
  const enabled = await guarded.execute({} as never, {teamId: "team-1"} as never);

  assert.equal(guarded.primitive, "googleDrive");
  assert.equal(disabled._unsafeUnwrapErr().code, "pluginDisabled");
  assert.deepEqual(disabled._unsafeUnwrapErr().details, {plugin: "googleDrive"});
  assert.deepEqual(enabled._unsafeUnwrap(), {ran: true});
});

test("triggers of a disabled plugin start no runs", async () => {
  const guarded = interpreterEnabledBy("shopware", interpreter, enabledIn("team-1"));

  assert.deepEqual(await guarded.interpret({teamId: "team-2"} as never, {} as never), []);
  assert.equal((await guarded.interpret({teamId: "team-1"} as never, {} as never)).length, 1);
});
