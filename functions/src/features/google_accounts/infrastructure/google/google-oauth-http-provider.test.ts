import assert from "node:assert/strict";
import test from "node:test";
import {GoogleAuthorizationRevokedError} from "../../domain/repositories/google-oauth-provider.js";
import {GoogleOAuthHttpProvider} from "./google-oauth-http-provider.js";

const client = {clientId: "client-id", clientSecret: "secret", redirectUri: "https://relay.test/callback"};

function providerAnswering(answer: (url: string, init?: RequestInit) => Response) {
  const calls: Array<{url: string; init?: RequestInit}> = [];
  const request = (async (url: string, init?: RequestInit) => {
    calls.push({url, init});
    return answer(url, init);
  }) as typeof fetch;
  return {provider: new GoogleOAuthHttpProvider(client, request), calls};
}

test("die Anmelde-Adresse fordert drive.file, Offline-Zugriff, PKCE und den Picker an", () => {
  const {provider} = providerAnswering(() => Response.json({}));
  const url = new URL(provider.authorizationUrl({state: "s", codeChallenge: "c", loginHint: "a@example.com"}));

  assert.equal(url.searchParams.get("scope"), "openid email https://www.googleapis.com/auth/drive.file");
  assert.equal(url.searchParams.get("access_type"), "offline");
  assert.equal(url.searchParams.get("code_challenge_method"), "S256");
  assert.equal(url.searchParams.get("trigger_onepick"), "true");
  assert.equal(url.searchParams.get("login_hint"), "a@example.com");
});

test("invalid_grant beim Erneuern heißt: Anmeldung zurückgezogen", async () => {
  const {provider} = providerAnswering(() => Response.json({error: "invalid_grant"}, {status: 400}));

  await assert.rejects(provider.refreshAccessToken("refresh"), GoogleAuthorizationRevokedError);
});

test("das Erneuern sendet Client-Secret und Refresh-Token und liefert die Gültigkeit", async () => {
  const {provider, calls} = providerAnswering(() => Response.json({access_token: "neu", expires_in: 3599}));

  assert.deepEqual(await provider.refreshAccessToken("refresh"), {accessToken: "neu", expiresInSeconds: 3599});
  const body = calls[0].init?.body as URLSearchParams;
  assert.equal(body.get("grant_type"), "refresh_token");
  assert.equal(body.get("client_secret"), "secret");
});

test("nicht mehr auffindbare Freigaben fehlen in der Beschreibung", async () => {
  const {provider} = providerAnswering((url) => url.includes("weg")
    ? new Response(null, {status: 404})
    : Response.json({id: "da", name: "Rechnungen", mimeType: "application/vnd.google-apps.folder"}));

  const items = await provider.describeItems({accessToken: "t", ids: ["da", "weg"]});

  assert.deepEqual(items, [{id: "da", name: "Rechnungen", mimeType: "application/vnd.google-apps.folder"}]);
});
