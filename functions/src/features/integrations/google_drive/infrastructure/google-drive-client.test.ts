import assert from "node:assert/strict";
import test from "node:test";
import {GoogleDriveError} from "../domain/google-drive-error.js";
import {GoogleDriveClient} from "./google-drive-client.js";

type Call = {url: string; init?: RequestInit};

function tokens() {
  const state = {issued: 0, invalidated: 0};
  return {state, token: async () => `token-${++state.issued}`, invalidate: () => void state.invalidated++};
}

function clientAnswering(answers: Array<(call: Call) => Response>) {
  const calls: Call[] = [];
  const source = tokens();
  const request = (async (url: string, init?: RequestInit) => {
    const call = {url: String(url), init};
    calls.push(call);
    return answers[Math.min(calls.length - 1, answers.length - 1)](call);
  }) as typeof fetch;
  return {client: new GoogleDriveClient(source, "konto-1", request), calls, tokens: source.state};
}

test("das Hochladen sendet Metadaten mit Zielordner und Inhalt als multipart", async () => {
  const {client, calls} = clientAnswering([() => Response.json({id: "neu", name: "a.txt", mimeType: "text/plain", webViewLink: "https://drive/neu", size: "5"})]);

  const file = await client.upload({name: "a.txt", mimeType: "text/plain", content: "Hallo", folderId: "ordner-1"});

  assert.deepEqual(file, {id: "neu", name: "a.txt", mimeType: "text/plain", webViewLink: "https://drive/neu", sizeBytes: 5});
  assert.match(calls[0].url, /upload\/drive\/v3\/files\?uploadType=multipart/);
  const body = Buffer.from(calls[0].init?.body as Uint8Array).toString("utf8");
  assert.match(body, /"parents":\["ordner-1"\]/);
  assert.match(body, /\r\n\r\nHallo\r\n--novooa-/);
  assert.equal((calls[0].init?.headers as Record<string, string>).authorization, "Bearer token-1");
});

test("ein Google-Dokument wird als PDF exportiert", async () => {
  const {client, calls} = clientAnswering([
    () => Response.json({name: "Angebot", mimeType: "application/vnd.google-apps.document"}),
    () => new Response(new Uint8Array([37, 80, 68, 70])),
  ]);

  const download = await client.download("doc-1");

  assert.equal(download.name, "Angebot.pdf");
  assert.equal(download.mimeType, "application/pdf");
  assert.deepEqual([...download.content], [37, 80, 68, 70]);
  assert.match(calls[1].url, /files\/doc-1\/export\?mimeType=application%2Fpdf/);
});

test("eine normale Datei kommt unverändert über alt=media", async () => {
  const {client, calls} = clientAnswering([
    () => Response.json({name: "rechnung.pdf", mimeType: "application/pdf"}),
    () => new Response(new Uint8Array([1, 2])),
  ]);

  assert.equal((await client.download("datei-1")).name, "rechnung.pdf");
  assert.match(calls[1].url, /files\/datei-1\?alt=media/);
});

test("nach 401 wird einmal mit frischem Token wiederholt", async () => {
  const {client, calls, tokens: state} = clientAnswering([
    () => new Response(null, {status: 401}),
    () => Response.json({id: "neu"}),
  ]);

  await client.upload({name: "a", mimeType: "text/plain", content: ""});

  assert.equal(calls.length, 2);
  assert.equal(state.invalidated, 1);
  assert.equal((calls[1].init?.headers as Record<string, string>).authorization, "Bearer token-2");
});

test("nicht freigegebene Dateien melden, wie man sie freigibt", async () => {
  const {client} = clientAnswering([() => new Response(null, {status: 404})]);

  await assert.rejects(client.download("fremd"), (error: unknown) =>
    error instanceof GoogleDriveError && /Weitere Dateien freigeben/.test(error.message));
});

test("verweigerter Zugriff nennt Googles Grund", async () => {
  const reason = {error: {message: "The user does not have sufficient permissions for this file."}};
  const {client} = clientAnswering([() => Response.json(reason, {status: 403})]);

  await assert.rejects(client.download("nur-lesen"), (error: unknown) =>
    error instanceof GoogleDriveError && /Status 403\): The user does not have sufficient permissions/.test(error.message));
});

test("ein voller Drive-Speicher wird verständlich gemeldet", async () => {
  const quota = {error: {message: "The user's Drive storage quota has been exceeded.", errors: [{reason: "storageQuotaExceeded"}]}};
  const {client} = clientAnswering([() => Response.json(quota, {status: 403})]);

  await assert.rejects(client.download("voll"), (error: unknown) =>
    error instanceof GoogleDriveError && /Speicher dieses Kontos ist voll/.test(error.message));
});
