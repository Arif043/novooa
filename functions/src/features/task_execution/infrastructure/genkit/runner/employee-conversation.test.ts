import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {EmployeeConversation} from "./employee-conversation.js";

function fakeEmployeeAi() {
  const ai = genkit({});
  const requests: string[] = [];
  let active = 0;
  let overlapped = false;
  const model = ai.defineModel({name: "fake-member"}, async (request) => {
    active += 1;
    overlapped ||= active > 1;
    requests.push(JSON.stringify(request.messages));
    await new Promise((resolve) => setTimeout(resolve, 5));
    active -= 1;
    return {message: {role: "model", content: [{text: `Antwort ${requests.length}`}]}, finishReason: "stop"};
  });
  return {ai, model, requests, overlapped: () => overlapped};
}

const employee = {id: "e", name: "Recherche", constraint: "Arbeite gründlich."};

test("a follow-up task sees the earlier task and answer", async () => {
  const {ai, model, requests} = fakeEmployeeAi();
  const conversation = new EmployeeConversation({ai, employee, model});

  assert.equal(await conversation.send("Finde A."), "Antwort 1");
  assert.equal(await conversation.send("Vertiefe A."), "Antwort 2");

  assert.match(requests[0], /"role":"system".*Arbeite gründlich\./);
  assert.match(requests[1], /Finde A\..*Antwort 1.*Vertiefe A\./);
});

test("parallel tasks run one after another in the same conversation", async () => {
  const {ai, model, requests, overlapped} = fakeEmployeeAi();
  const conversation = new EmployeeConversation({ai, employee, model});

  const answers = await Promise.all([conversation.send("Erstens."), conversation.send("Zweitens.")]);

  assert.deepEqual(answers, ["Antwort 1", "Antwort 2"]);
  assert.equal(overlapped(), false);
  assert.match(requests[1], /Erstens\..*Zweitens\./);
});

test("a failed task does not block the next one", async () => {
  const ai = genkit({});
  let calls = 0;
  const model = ai.defineModel({name: "flaky-member"}, async () => {
    calls += 1;
    if (calls === 1) throw new Error("kaputt");
    return {message: {role: "model", content: [{text: "ok"}]}, finishReason: "stop"};
  });
  const conversation = new EmployeeConversation({ai, employee, model});

  await assert.rejects(conversation.send("Eins."));
  assert.equal(await conversation.send("Zwei."), "ok");
});
