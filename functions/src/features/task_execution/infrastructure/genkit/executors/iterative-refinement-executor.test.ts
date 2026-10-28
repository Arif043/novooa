import assert from "node:assert/strict";
import test from "node:test";
import {type IterativeRefinementRequest} from "../../../domain/entities/iterative-refinement-execution.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {executeIterativeRefinementNode} from "./genkit-iterative-refinement-executor.js";

type Call = {system?: string; prompt: unknown; output?: {schema?: unknown}; config?: Record<string, unknown>};
type Answer = {text?: string; output?: unknown} | Error;

test("evaluates, improves with the feedback and stops once the criteria are met", async () => {
  const {ai, calls} = fakeAi([
    {text: "", output: {critique: "Zu lang.", satisfied: false}},
    {text: "Kurze Fassung."},
    {text: "", output: {critique: "Passt.", satisfied: true}},
  ]);

  const result = await executeIterativeRefinementNode(ai, request(), undefined, silentLogger());

  assert.deepEqual(result, {answer: "Kurze Fassung.", iterations: 2});
  const [evaluation, improvement] = calls;
  assert.ok(evaluation?.output?.schema, "the evaluation asks for a schema");
  assert.match(evaluation?.system ?? "", /<role>\nYou review a draft/);
  assert.equal(userText(evaluation), [
    "<task>\nHöchstens zwei Sätze.\n</task>",
    "<context name=\"objective\">\nEine knappe Antwort.\n</context>",
    "<context name=\"draft\">\nLanger Entwurf.\n</context>",
  ].join("\n\n"));
  assert.match(improvement?.system ?? "", /<role>\nYou revise a draft/);
  assert.match(userText(improvement), /<task>\nKürze den Text\.\n<\/task>/);
  assert.match(userText(improvement), /<context name="feedback">\nZu lang\.\n<\/context>/);
  assert.deepEqual(improvement?.config, {temperature: 0.4});
});

test("falls back to a text evaluation when the structured one fails", async () => {
  const {ai, calls} = fakeAi([
    new Error("Schema kaputt"),
    {text: "Hier: {\"critique\": \"Gut.\", \"satisfied\": true}"},
  ]);

  const result = await executeIterativeRefinementNode(ai, request(), undefined, silentLogger());

  assert.deepEqual(result, {answer: "Langer Entwurf.", iterations: 1});
  assert.equal(calls[1]?.output, undefined, "the fallback asks for plain text");
  assert.match(calls[1]?.system ?? "", /<output_format>\nAnswer only with a JSON object/);
});

test("an employee adds its constraint as a system section to every call", async () => {
  const {ai, calls} = fakeAi([{text: "", output: {critique: "Passt.", satisfied: true}}]);

  await executeIterativeRefinementNode(ai, request({
    employee: {id: "e-1", name: "Lektorat", constraint: "Achte auf Stil."},
  }), undefined, silentLogger());

  assert.match(calls[0]?.system ?? "", /<employee name="Lektorat">\nAchte auf Stil\.\n<\/employee>/);
  assert.match(calls[0]?.system ?? "", /Act as the employee described in <employee>/);
});

function request(overrides: Partial<IterativeRefinementRequest> = {}): IterativeRefinementRequest {
  return {
    objective: "Eine knappe Antwort.", draft: "Langer Entwurf.", optimizerPrompt: "Kürze den Text.",
    critiquePrompt: "Höchstens zwei Sätze.", maxIterations: 3, ...overrides,
  };
}

function fakeAi(answers: Answer[]) {
  const calls: Call[] = [];
  const ai = {generate: (options: Call) => {
    calls.push(options);
    const answer = answers.shift() ?? {text: ""};
    return answer instanceof Error ? Promise.reject(answer) : Promise.resolve({text: "", ...answer});
  }};
  return {ai: ai as never, calls};
}

function userText(call: Call | undefined): string {
  return typeof call?.prompt === "string" ? call.prompt : "";
}

function silentLogger(): ApplicationLogger {
  return {readableInfo() {}, readableError() {}, info() {}, error() {}, exception() {}};
}
