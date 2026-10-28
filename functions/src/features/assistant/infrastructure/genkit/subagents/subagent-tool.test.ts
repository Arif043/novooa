import assert from "node:assert/strict";
import test from "node:test";
import {PromptBuilder} from "../../../../language_models/domain/prompting/prompt-builder.js";
import {z} from "genkit";
import {DelegationBudget} from "./delegation-budget.js";
import {defineSubagentTool, type SubagentGenkit, type SubagentResult} from "./subagent-tool.js";

type ToolFn = (input: unknown, options: {context: unknown}) => Promise<SubagentResult<unknown>>;

const outputSchema = z.object({antwort: z.string()});

function fakeGenkit(generate: () => Promise<{output: unknown}>) {
  const calls: unknown[] = [];
  const ai = {
    dynamicTool: (_config: unknown, fn: ToolFn) => fn,
    generate: async (request: unknown) => {
      calls.push(request);
      return generate();
    },
  } as unknown as SubagentGenkit;
  return {ai, calls};
}

function toolFor(
  ai: SubagentGenkit,
  budget = new DelegationBudget(5),
  finalize?: (output: {antwort: string}) => {antwort: string},
): ToolFn {
  const spec = {
    name: "testagent",
    description: "Test",
    model: "test/model",
    instructions: PromptBuilder.create().role("System"),
    tools: [],
    inputSchema: z.object({frage: z.string()}),
    outputSchema,
    maxTurns: 2,
    finalize,
  };
  return defineSubagentTool(ai, spec, budget) as unknown as ToolFn;
}

test("returns the structured subagent output and forwards the actor context", async () => {
  const {ai, calls} = fakeGenkit(async () => ({output: {antwort: "42"}}));

  const result = await toolFor(ai)({frage: "?"}, {context: {assistant: {actorId: "u1"}}});

  assert.deepEqual(result, {ok: true, ergebnis: {antwort: "42"}});
  assert.deepEqual((calls[0] as {context: unknown}).context, {assistant: {actorId: "u1"}});
});

test("applies the deterministic post check to a valid output", async () => {
  const {ai} = fakeGenkit(async () => ({output: {antwort: "42"}}));
  const tool = toolFor(ai, new DelegationBudget(5), ({antwort}) => ({antwort: `${antwort} geprüft`}));

  const result = await tool({frage: "?"}, {context: undefined});

  assert.deepEqual(result.ergebnis, {antwort: "42 geprüft"});
});

test("reports an invalid structured output as a tool failure", async () => {
  const {ai} = fakeGenkit(async () => ({output: {falsch: true}}));

  const result = await toolFor(ai)({frage: "?"}, {context: undefined});

  assert.equal(result.ok, false);
});

test("reports a model error as a tool failure instead of throwing", async () => {
  const {ai} = fakeGenkit(async () => {
    throw new Error("Modell nicht erreichbar");
  });

  const result = await toolFor(ai)({frage: "?"}, {context: undefined});

  assert.equal(result.ok, false);
  assert.match(result.grund ?? "", /Modell nicht erreichbar/);
});

test("stops delegating once the budget is exhausted", async () => {
  const {ai, calls} = fakeGenkit(async () => ({output: {antwort: "ok"}}));
  const tool = toolFor(ai, new DelegationBudget(1));

  await tool({frage: "1"}, {context: undefined});
  const second = await tool({frage: "2"}, {context: undefined});

  assert.equal(second.ok, false);
  assert.equal(calls.length, 1);
});

test("rejects an empty delegation budget", () => {
  assert.throws(() => new DelegationBudget(0));
});
