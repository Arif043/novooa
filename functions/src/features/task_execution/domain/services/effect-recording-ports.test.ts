import assert from "node:assert/strict";
import test from "node:test";
import {EffectRecordingDocumentStore} from "./effect-recording-document-store.js";
import {
  EffectRecordingHttpClient,
  EffectRecordingMessageSender,
  EffectRecordingTeamFileStore,
} from "./effect-recording-ports.js";
import {RunEffectRecorder} from "./run-effect-recorder.js";

const recorder = () => RunEffectRecorder.root().child("baustein");

test("a written file becomes a fileWritten effect with its version", async () => {
  const effects = recorder();
  const store = new EffectRecordingTeamFileStore({
    writeTeamFile: async () => ({
      fileId: "f1", versionId: "v1", storagePath: "p", displayName: "bericht.md", contentType: "text/markdown",
      sizeBytes: 12, folderId: null, ownerUid: "system", isNewFile: true,
    }),
  } as never, effects);

  await store.writeTeamFile({teamId: "t", content: "x", fileName: "bericht.md", contentType: "text/markdown", targetFileId: null});

  assert.deepEqual(effects.effects, [{
    kind: "fileWritten", fileId: "f1", versionId: "v1", displayName: "bericht.md", contentType: "text/markdown",
    sizeBytes: 12, isNewFile: true, sourceNodeId: "baustein",
  }]);
});

test("a failed port call leaves no effect", async () => {
  const effects = recorder();
  const sender = new EffectRecordingMessageSender({send: () => Promise.reject(new Error("SMTP"))}, effects);

  await assert.rejects(sender.send({kind: "sms", teamId: "t", recipient: "+49", body: "Hallo"}));

  assert.equal(effects.effects.length, 0);
});

test("a sent message keeps channel, recipient and subject, never the text", async () => {
  const effects = recorder();
  const sender = new EffectRecordingMessageSender({
    send: async () => ({outboundId: "o", providerMessageId: "p", channelId: "c"}),
  }, effects);

  await sender.send({kind: "email", teamId: "t", recipient: "kunde@example.com", subject: "Rechnung", body: "Geheim", connectorId: "m"});

  assert.deepEqual(effects.effects, [{
    kind: "messageSent", channel: "email", recipient: "kunde@example.com", subject: "Rechnung", sourceNodeId: "baustein",
  }]);
  assert.doesNotMatch(JSON.stringify(effects.effects), /Geheim/);
});

test("HTTP: reads are no effect, a change keeps only method, host and status", async () => {
  const effects = recorder();
  const client = new EffectRecordingHttpClient({send: async () => ({status: 201, headers: {}, body: "{}"})}, effects);
  const request = {
    teamId: "t", url: "https://api.example.com/orders?token=geheim", query: [{name: "a", value: "b"}],
    headers: {authorization: "Bearer geheim"}, body: "{\"x\":1}", timeoutMs: 1000,
  };

  await client.send({...request, method: "GET"});
  await client.send({...request, method: "POST"});

  assert.deepEqual(effects.effects, [{kind: "httpRequested", method: "POST", status: 201, host: "api.example.com", sourceNodeId: "baustein"}]);
  assert.doesNotMatch(JSON.stringify(effects.effects), /geheim/);
});

test("records: an upsert of a new record is created, an existing one updated; empty deletes are no effect", async () => {
  const effects = recorder();
  let version = 1;
  const store = new EffectRecordingDocumentStore({
    upsert: async () => ({id: "d1", teamId: "t", collectionId: "c1", data: {}, version, createdAt: new Date(), updatedAt: new Date()}),
    deleteDocuments: async () => 0,
    findMany: async () => [],
  } as never, effects);
  const input = {teamId: "t", collectionId: "c1", documentId: "d1", data: {}};

  await store.upsert(input);
  version = 2;
  await store.upsert(input);
  await store.deleteDocuments({teamId: "t", collectionId: "c1"});
  await store.findMany({teamId: "t", collectionId: "c1"});

  assert.deepEqual(effects.effects.map((effect) => effect.kind === "recordsChanged" && effect.operation), ["created", "updated"]);
});
