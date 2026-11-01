import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {GenkitTeamworkExecutor} from "./genkit-teamwork-executor.js";
import {fakeModel, logger, request, teamLogging, resolverFor, result, workspaceFor, type FakeModel} from "./teamwork-test-support.js";

const reviewed = {...request, review: {enabled: true, languageModelId: "reviewer"}};
const verdict = (approved: boolean, findings = "") => ({text: JSON.stringify({approved, findings})});

async function executorFor(
  t: Parameters<typeof workspaceFor>[0], models: Record<string, FakeModel>,
  capabilitiesById: Parameters<typeof resolverFor>[2] = {},
) {
  const log = logger();
  const logging = teamLogging(log);
  // Ohne Mitarbeiter: Diese Tests prüfen nur die Prüfung, nicht die Delegation.
  const workspace = await workspaceFor(t);
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: {...workspace, team: {...workspace.team, members: []}}, ...logging,
    languageModelResolver: resolverFor({worker: fakeModel("worker", () => ({text: ""})), ...models}, {toolCalling: true}, capabilitiesById),
  });
  return {executor, log, transcript: logging.transcript};
}

test("an approved result is delivered after one review on the reviewer's own model", async (t) => {
  const orchestrator = fakeModel("orchestrator", () => result("X ist 42 groß", 42));
  const reviewer = fakeModel("reviewer", () => verdict(true));
  const {executor, log} = await executorFor(t, {orchestrator, reviewer});

  const outcome = (await executor.execute(reviewed))._unsafeUnwrap();

  assert.deepEqual(outcome.fields, {antwort: "X ist 42 groß", groesse: 42});
  assert.equal(orchestrator.requests.length, 1);
  assert.match(reviewer.requests[0].messages, /Wie groß ist X\?.*X ist 42 groß/);
  assert.ok(reviewer.requests[0].tools.includes("read_file"));
  assert.ok(!reviewer.requests[0].tools.includes("write_file"), "the review only reads");
  assert.ok(log.lines.includes("[Teamwork] Review 1 passed"));
});

test("a rejected result is revised in the same orchestrator conversation", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => (call === 1 ? result("X", 0) : result("X ist 42 groß", 42)));
  const reviewer = fakeModel("reviewer", (call) => (call === 1 ? verdict(false, "Die Größe fehlt.") : verdict(true)));
  const {executor, log, transcript} = await executorFor(t, {orchestrator, reviewer});

  const outcome = (await executor.execute(reviewed))._unsafeUnwrap();

  assert.deepEqual(transcript.entries().map(({kind, round, text}) => [kind, round, text]).slice(0, 2), [
    ["reviewRejected", 1, "Die Größe fehlt."], ["reviewPassed", 2, ""],
  ]);
  assert.deepEqual(outcome.fields, {antwort: "X ist 42 groß", groesse: 42});
  assert.match(orchestrator.requests[1].messages, /You lead a team.*Wie groß ist X\?.*<context name=\\"findings\\">\\nDie Größe fehlt\./,
    "the revision continues the same conversation");
  assert.ok(log.lines.some((line) => line.startsWith("[Teamwork] Review 1 rejected\nDie Größe fehlt.")));
  assert.ok(log.lines.includes("[Teamwork] Review 2 passed"));
});

test("after two revisions the last result is delivered with the open findings in the log", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => result(`Versuch ${call}`, call));
  const reviewer = fakeModel("reviewer", () => verdict(false, "Immer noch falsch."));
  const {executor, log} = await executorFor(t, {orchestrator, reviewer});

  const outcome = (await executor.execute(reviewed))._unsafeUnwrap();

  assert.deepEqual(outcome.fields, {antwort: "Versuch 3", groesse: 3});
  assert.equal(orchestrator.requests.length, 3);
  assert.equal(reviewer.requests.length, 3);
  assert.ok(log.lines.some((line) => line.startsWith("[Teamwork] Review 3 rejected – no revisions left")));
});

test("without review no reviewer model is resolved or called", async (t) => {
  const orchestrator = fakeModel("orchestrator", () => result("X", 1));
  const reviewer = fakeModel("reviewer", () => verdict(true));
  const {executor} = await executorFor(t, {orchestrator, reviewer});

  (await executor.execute({...reviewed, review: {enabled: false, languageModelId: "reviewer"}}))._unsafeUnwrap();

  assert.equal(reviewer.requests.length, 0);
});

test("a reviewer whose provider rejects structured output fails readably", async (t) => {
  const orchestrator = fakeModel("orchestrator", () => result("X", 1));
  const reviewer = fakeModel("reviewer", () => { throw new Error("response_format json_schema is not supported by this model"); });
  const {executor} = await executorFor(t, {orchestrator, reviewer}, {reviewer: {structuredOutput: false}});

  const failure = (await executor.execute(reviewed))._unsafeUnwrapErr();

  assert.equal(failure.code, "capabilityMissing");
  assert.match(failure.message, /unterstützt strukturierte Ausgabe nicht/);
});
