import assert from "node:assert/strict";
import test from "node:test";
import {connectionInputFrom, connectionSecretFrom} from "./entities/connection-request.js";
import {ConnectionRequestError} from "./entities/connection.js";

const valid = {name: "  Shop  ", baseUrl: "https://shop.example.com/api/", auth: {kind: "bearer"}};

test("eine gültige Eingabe wird normalisiert", () => {
  assert.deepEqual(connectionInputFrom(valid), {name: "Shop", baseUrl: "https://shop.example.com/api", auth: {kind: "bearer"}});
  assert.equal(connectionInputFrom({...valid, baseUrl: "http://localhost:8080/"}).baseUrl, "http://localhost:8080");
});

test("alle Anmeldearten werden mit ihren Feldern übernommen", () => {
  assert.deepEqual(connectionInputFrom({...valid, auth: {kind: "apiKey", headerName: " X-API-Key "}}).auth, {kind: "apiKey", headerName: "X-API-Key"});
  assert.deepEqual(
    connectionInputFrom({...valid, auth: {kind: "oauthClientCredentials", tokenUrl: "https://shop.example.com/api/oauth/token", clientId: "abc", scope: " write "}}).auth,
    {kind: "oauthClientCredentials", tokenUrl: "https://shop.example.com/api/oauth/token", clientId: "abc", scope: "write"},
  );
  assert.equal("scope" in connectionInputFrom({...valid, auth: {kind: "oauthClientCredentials", tokenUrl: "https://t.example/token", clientId: "abc"}}).auth, false);
});

test("ungültige Eingaben nennen den Grund auf Deutsch", () => {
  const rejects = (body: Parameters<typeof connectionInputFrom>[0], pattern: RegExp) =>
    assert.throws(() => connectionInputFrom(body), (error: unknown) => error instanceof ConnectionRequestError && pattern.test(error.message));
  rejects({...valid, name: " "}, /Name/);
  rejects({...valid, name: "x".repeat(81)}, /Name/);
  rejects({...valid, baseUrl: "kein url"}, /Basis-URL.*gültige/);
  rejects({...valid, baseUrl: "ftp://shop.example.com"}, /https:\/\//);
  rejects({...valid, baseUrl: "https://user:pass@shop.example.com"}, /Zugangsdaten/);
  rejects({...valid, baseUrl: "https://shop.example.com/api?key=1"}, /Parameter/);
  rejects({...valid, auth: {kind: "apiKey", headerName: "X API Key"}}, /Header-Name/);
  rejects({...valid, auth: {kind: "apiKey"}}, /Header-Name/);
  rejects({...valid, auth: {kind: "basic"}}, /Anmeldeart/);
  rejects({...valid, auth: undefined}, /Anmeldeart/);
  rejects({...valid, auth: {kind: "oauthClientCredentials", tokenUrl: "https://t.example/token"}}, /Client-ID/);
  rejects({...valid, auth: {kind: "oauthClientCredentials", clientId: "abc", tokenUrl: "nope"}}, /Token-URL/);
});

test("das Geheimnis wird getrimmt und ist Pflicht", () => {
  assert.equal(connectionSecretFrom("  geheim\n"), "geheim");
  assert.throws(() => connectionSecretFrom(undefined), ConnectionRequestError);
  assert.throws(() => connectionSecretFrom("  "), ConnectionRequestError);
  assert.throws(() => connectionSecretFrom("x".repeat(4097)), /zu lang/);
});
