import assert from "node:assert/strict";
import test from "node:test";
import {routeMatch} from "./local-runtime-route.js";
import {type LocalRuntimeRequest} from "./local-runtime-http-server.js";

function request(method: string, url: string): LocalRuntimeRequest {
  return {method, url, body: {}};
}

test("eine feste Route passt exakt", () => {
  const match = routeMatch(request("GET", "/v1/files"), "GET", "/v1/files");

  assert.deepEqual(match?.params, {});
});

test("eine andere Methode passt nicht", () => {
  assert.equal(routeMatch(request("POST", "/v1/files"), "GET", "/v1/files"), null);
});

test("extrahiert einen Pfadparameter", () => {
  const match = routeMatch(request("GET", "/v1/tasks/task-1"), "GET", "/v1/tasks/:taskId");

  assert.equal(match?.params.taskId, "task-1");
});

test("extrahiert mehrere Pfadparameter", () => {
  const match = routeMatch(
    request("GET", "/v1/files/f1/versions/v2/content"),
    "GET",
    "/v1/files/:fileId/versions/:versionId/content",
  );

  assert.equal(match?.params.fileId, "f1");
  assert.equal(match?.params.versionId, "v2");
});

test("ein zu kurzer oder zu langer Pfad passt nicht", () => {
  const pattern = "/v1/files/:fileId/versions";

  assert.equal(routeMatch(request("GET", "/v1/files/f1"), "GET", pattern), null);
  assert.equal(
    routeMatch(request("GET", "/v1/files/f1/versions/v2"), "GET", pattern),
    null,
  );
});

test("ein leeres Segment ist kein Treffer", () => {
  assert.equal(
    routeMatch(request("GET", "/v1/files//versions"), "GET", "/v1/files/:fileId/versions"),
    null,
  );
});

test("ein Parameter frisst keinen Schrägstrich", () => {
  assert.equal(
    routeMatch(request("GET", "/v1/tasks/a/b"), "GET", "/v1/tasks/:taskId"),
    null,
  );
});

test("Query-Strings werden abgeschnitten", () => {
  const match = routeMatch(
    request("GET", "/v1/tasks/task-1?felder=alle"),
    "GET",
    "/v1/tasks/:taskId",
  );

  assert.equal(match?.params.taskId, "task-1");
});

test("Parameterwerte werden URL-dekodiert", () => {
  const match = routeMatch(
    request("GET", "/v1/files/mein%20ordner"),
    "GET",
    "/v1/files/:fileId",
  );

  assert.equal(match?.params.fileId, "mein ordner");
});

test("ein abschliessender Schrägstrich ändert nichts", () => {
  assert.deepEqual(
    routeMatch(request("GET", "/v1/files/"), "GET", "/v1/files")?.params,
    {},
  );
});

test("ein anderer Pfad gleicher Länge passt nicht", () => {
  assert.equal(
    routeMatch(request("GET", "/v1/folders/f1"), "GET", "/v1/files/:fileId"),
    null,
  );
});

test("eine fehlende URL passt nicht", () => {
  assert.equal(routeMatch({method: "GET", body: {}}, "GET", "/v1/files"), null);
});
