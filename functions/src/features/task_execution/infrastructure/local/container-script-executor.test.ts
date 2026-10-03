import assert from "node:assert/strict";
import {mkdtemp, rm, writeFile} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, {afterEach} from "node:test";
import {type ScriptWorkspace} from "../../domain/entities/script-execution.js";
import {
  createContainerScriptExecutorFactory,
  maximumAttachmentBytes,
  unavailableScriptExecutorFactory,
} from "./container-script-executor.js";

const originalFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = originalFetch; });

const request = {input: "eingabe", script: "output = input", variables: {zaehler: 1}};

function respondWith(status: number, body: unknown) {
  const sent: {url: string; form: FormData}[] = [];
  globalThis.fetch = (async (url: URL | string, init?: RequestInit) => {
    sent.push({url: String(url), form: init?.body as FormData});
    return new Response(JSON.stringify(body), {status, headers: {"content-type": "application/json"}});
  }) as typeof fetch;
  return sent;
}

async function workspaceWith(files: {displayName: string; bytes: Buffer; contentType?: string}[]) {
  const rootDirectory = await mkdtemp(path.join(os.tmpdir(), "script-test-"));
  for (const [index, file] of files.entries()) await writeFile(path.join(rootDirectory, `f${index}`), file.bytes);
  const workspace: ScriptWorkspace = {
    rootDirectory,
    files: files.map((file, index) => ({
      displayName: file.displayName, contentType: file.contentType ?? "application/octet-stream",
      sizeBytes: file.bytes.length, filename: `f${index}`,
    })),
  };
  return {workspace, cleanup: () => rm(rootDirectory, {recursive: true, force: true})};
}

const executor = (workspace?: ScriptWorkspace) => createContainerScriptExecutorFactory("http://script:8091")(workspace);

test("schickt Script, Eingabe und Variablen an /run und liefert die Antwort des Dienstes", async () => {
  const sent = respondWith(200, {outputDefined: true, output: "ERGEBNIS", printed: "hallo\n", variables: {zaehler: 2}});

  const result = await executor().execute(request);

  assert.deepEqual(result, {output: "ERGEBNIS", printed: "hallo\n", variables: {zaehler: 2}});
  assert.equal(sent[0].url, "http://script:8091/run");
  const body = JSON.parse(await (sent[0].form.get("request") as Blob).text());
  assert.deepEqual(body, {script: "output = input", input: "eingabe", variables: {zaehler: 1}, files: []});
});

test("angehängte Dateien gehen als rohe Bytes mit, ohne Kodierung", async () => {
  const bytes = Buffer.from([0x00, 0xff, 0x0d, 0x0a, 0x89, 0x50, 0x4e, 0x47]);
  const {workspace, cleanup} = await workspaceWith([{displayName: "bild.png", bytes, contentType: "image/png"}]);
  const sent = respondWith(200, {outputDefined: true, output: "", printed: "", variables: {}});

  await executor(workspace).execute(request);
  await cleanup();

  const file = sent[0].form.get("file-0") as Blob;
  assert.deepEqual(Buffer.from(await file.arrayBuffer()), bytes);
  assert.equal(file.type, "image/png");
  const body = JSON.parse(await (sent[0].form.get("request") as Blob).text());
  assert.deepEqual(body.files, [{displayName: "bild.png", contentType: "image/png", sizeBytes: bytes.length}]);
});

test("setzt das Script keinen output, bleibt die Eingabe", async () => {
  respondWith(200, {outputDefined: false, output: null, printed: "", variables: {}});

  assert.equal((await executor().execute(request)).output, "eingabe");
});

test("ein gescheitertes Script liefert die lesbare Meldung des Dienstes", async () => {
  respondWith(422, {error: "Zeile 2: ZeroDivisionError: division by zero"});

  await assert.rejects(executor().execute(request), /Zeile 2: ZeroDivisionError/);
});

test("ein nicht erreichbarer Dienst wird verständlich gemeldet", async () => {
  globalThis.fetch = (async () => { throw new TypeError("fetch failed"); }) as typeof fetch;

  await assert.rejects(executor().execute(request), /Script-Dienst ist nicht erreichbar/);
});

test("zu große Anhänge werden abgelehnt, bevor etwas gesendet wird", async () => {
  const sent = respondWith(200, {});
  const workspace: ScriptWorkspace = {
    rootDirectory: os.tmpdir(),
    files: [{displayName: "riesig.bin", contentType: "x", sizeBytes: maximumAttachmentBytes + 1, filename: "x"}],
  };

  await assert.rejects(executor(workspace).execute(request), /größer als 25 MB/);
  assert.equal(sent.length, 0);
});

test("ohne Adresse des Dienstes läuft kein Script", async () => {
  await assert.rejects(unavailableScriptExecutorFactory()().execute(request), /SCRIPT_RUNNER_URL/);
});
