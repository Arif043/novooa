import assert from "node:assert/strict";
import test, {afterEach} from "node:test";
import {MailProviderAuthorizationError, MailProviderRequestError} from "../../domain/repositories/mail-provider.js";
import {graphRequest, tokenFromForm} from "./microsoft-graph-http.js";

const originalFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = originalFetch;
});

function respondWith(status: number, body: unknown) {
  globalThis.fetch = (async () => new Response(JSON.stringify(body), {status, headers: {"Content-Type": "application/json"}})) as typeof fetch;
}

test("ein ungültiges Refresh Token wird als Anmeldeproblem erkannt", async () => {
  for (const code of ["invalid_grant", "interaction_required", "consent_required", "login_required"]) {
    respondWith(400, {error: code, error_description: "AADSTS70008: abgelaufen\r\nTrace ID: x"});

    await assert.rejects(
      tokenFromForm(new URLSearchParams()),
      (error: unknown) => error instanceof MailProviderAuthorizationError && error.code === code,
      code,
    );
  }
});

test("andere Token-Fehler sind keine Anmeldeprobleme", async () => {
  for (const [status, code] of [[400, "invalid_client"], [503, "temporarily_unavailable"], [500, "server_error"]] as const) {
    respondWith(status, {error: code});

    await assert.rejects(
      tokenFromForm(new URLSearchParams()),
      (error: unknown) => error instanceof MailProviderRequestError && error.status === status,
      code,
    );
  }
});

test("die Token-Antwort liefert die Gültigkeit des Zugriffstokens", async () => {
  respondWith(200, {access_token: "a", refresh_token: "r", expires_in: 3599});

  assert.deepEqual(await tokenFromForm(new URLSearchParams()), {accessToken: "a", refreshToken: "r", expiresInSeconds: 3599});
});

test("eine Antwort ohne Gültigkeit lässt das Feld weg", async () => {
  respondWith(200, {access_token: "a", refresh_token: "r"});

  assert.deepEqual(await tokenFromForm(new URLSearchParams()), {accessToken: "a", refreshToken: "r"});
});

test("Graph-Fehler tragen den HTTP-Status; 404 gilt als nicht gefunden", async () => {
  respondWith(404, {error: {code: "ResourceNotFound", message: "The object was not found."}});

  await assert.rejects(
    graphRequest("/v1.0/subscriptions/x", "token"),
    (error: unknown) => error instanceof MailProviderRequestError && error.isNotFound && /not found/.test(error.message),
  );

  respondWith(401, {error: {message: "expired"}});
  await assert.rejects(
    graphRequest("/v1.0/me", "token"),
    (error: unknown) => error instanceof MailProviderRequestError && error.status === 401 && !error.isNotFound,
  );
});
