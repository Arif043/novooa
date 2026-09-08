import assert from "node:assert/strict";
import test from "node:test";
import {localRuntimeResponseFor} from "./local-runtime-http-server.js";

test("reports health through the local runtime API", async () => {
  assert.deepEqual(await localRuntimeResponseFor({body: {}, method: "GET", url: "/healthz"}), {
    body: {status: "ok"},
    statusCode: 200,
  });
});

test("rejects unknown local runtime endpoints", async () => {
  assert.deepEqual(await localRuntimeResponseFor({body: {}, method: "GET", url: "/unbekannt"}), {
    body: {error: "Endpunkt nicht gefunden."},
    statusCode: 404,
  });
});

test("leaves unexpected endpoint errors visible to the server adapter", async () => {
  const handler = {handle: async () => { throw new Error("Datenbank nicht erreichbar"); }};

  await assert.rejects(
    () => localRuntimeResponseFor({body: {}, method: "POST", url: "/v1/task-runs"}, handler),
    /Datenbank nicht erreichbar/,
  );
});
