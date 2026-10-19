import assert from "node:assert/strict";
import {writeFile} from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import {genkit} from "genkit/beta";
import {GenkitError} from "genkit";
import {GenkitTeamworkExecutor} from "./genkit-teamwork-executor.js";
import {delegation, fakeModel, logger, request, teamLogging, resolverFor, result, workspaceFor} from "./teamwork-test-support.js";

test("the orchestrator delegates to a member on its own model and returns the structured result", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => call === 1
    ? delegation("1", "Finde die Größe von X.")
    : result("X ist 42 groß", 42));
  const worker = fakeModel("worker", () => ({text: "X ist 42."}));
  const log = logger();
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), ...teamLogging(log),
    languageModelResolver: resolverFor({orchestrator, worker}),
  });

  const outcome = (await executor.execute(request))._unsafeUnwrap();

  assert.deepEqual(outcome.fields, {antwort: "X ist 42 groß", groesse: 42});
  assert.ok(orchestrator.requests[0].tools.includes("delegate_to_recherche"));
  assert.match(orchestrator.requests[0].messages, /Findet Fakten/);
  assert.match(worker.requests[0].messages, /"role":"system".*Du recherchierst gründlich/);
  assert.match(worker.requests[0].messages, /Auftrag:\\nFinde die Größe von X\..*Erwartetes Ergebnis:\\nEine Zahl\..*shared\//);
  assert.ok(worker.requests[0].tools.includes("write_file"), "members may write to the shared folder");
  assert.match(orchestrator.requests[1].messages, /X ist 42\./);
  assert.ok(log.lines.some((line) => line.startsWith("[Teamwork] Task for Recherche\nTask: Finde die Größe von X.\nExpected result: Eine Zahl.")));
  assert.ok(log.lines.some((line) => line.startsWith("[Teamwork] Answer from Recherche (")));
});

test("a failing member is reported to the orchestrator, which keeps working", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => call === 1 ? delegation("1", "Hilf.") : result("ohne Hilfe", 0));
  const worker = fakeModel("worker", () => {
    throw new GenkitError({status: "INVALID_ARGUMENT", message: "Modell lehnt ab"});
  });
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), ...teamLogging(),
    languageModelResolver: resolverFor({orchestrator, worker}),
  });

  const outcome = (await executor.execute(request))._unsafeUnwrap();

  assert.equal(outcome.fields.antwort, "ohne Hilfe");
  assert.match(orchestrator.requests[1].messages, /Der Auftrag an Recherche ist gescheitert/);
});

test("an orchestrator model without tool calls fails readably before anything runs", async (t) => {
  const orchestrator = fakeModel("orchestrator", () => ({text: "{}"}));
  const worker = fakeModel("worker", () => ({text: ""}));
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), ...teamLogging(),
    languageModelResolver: resolverFor({orchestrator, worker}, {toolCalling: false}),
  });

  const failure = (await executor.execute(request))._unsafeUnwrapErr();

  assert.match(failure.message, /Orchestrator unterstützt keine Werkzeugaufrufe/);
  assert.equal(orchestrator.requests.length, 0);
});

test("result files written to the shared folder are reported by path", async (t) => {
  const workspace = await workspaceFor(t);
  await writeFile(path.join(workspace.team.sharedDirectory, "bericht.md"), "# Bericht");
  const orchestrator = fakeModel("orchestrator", () => ({text: JSON.stringify({bericht: "shared/bericht.md"})}));
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace, ...teamLogging(),
    languageModelResolver: resolverFor({orchestrator, worker: fakeModel("worker", () => ({text: ""}))}),
  });

  const outcome = (await executor.execute({
    ...request, outputFields: [{name: "bericht", description: "", type: "file", fileFormat: "markdown"}],
  }))._unsafeUnwrap();

  assert.deepEqual(outcome.fields, {bericht: "shared/bericht.md"});
  assert.match(orchestrator.requests[0].messages, /bericht: Markdown/);
});

test("a member remembers earlier tasks of the run", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => call === 1 ? delegation("1", "Finde X.")
    : call === 2 ? delegation("2", "Und wie sicher ist das?") : result("X ist 42 groß", 42));
  const worker = fakeModel("worker", (call) => ({text: call === 1 ? "X ist 42." : "Sehr sicher."}));
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), ...teamLogging(),
    languageModelResolver: resolverFor({orchestrator, worker}),
  });

  (await executor.execute(request))._unsafeUnwrap();

  assert.match(worker.requests[1].messages, /Finde X\..*X ist 42\..*Und wie sicher ist das\?/);
});

test("the transcript holds the conversation: task, answer and result", async (t) => {
  const orchestrator = fakeModel("orchestrator", (call) => call === 1 ? delegation("1", "Finde X.") : result("X ist 42 groß", 42));
  const worker = fakeModel("worker", () => ({text: "X ist 42."}));
  const logging = teamLogging();
  const executor = new GenkitTeamworkExecutor({
    ai: genkit({}), workspace: await workspaceFor(t), ...logging,
    languageModelResolver: resolverFor({orchestrator, worker}),
  });

  (await executor.execute(request))._unsafeUnwrap();

  assert.deepEqual(logging.transcript.entries().map(({kind, memberName, text}) => [kind, memberName, text]), [
    ["task", "Recherche", "Finde X."],
    ["answer", "Recherche", "X ist 42."],
    ["result", undefined, JSON.stringify({antwort: "X ist 42 groß", groesse: 42}, null, 2)],
  ]);
});
