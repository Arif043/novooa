import assert from "node:assert/strict";
import test from "node:test";
import {RelayListCache} from "../../../../shared/local/relay-list-cache.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {type GoogleAccountSummary} from "../../domain/entities/google-account.js";
import {GoogleReauthorizationRequiredError} from "../../domain/repositories/google-access-tokens.js";
import {GoogleAccountsWakeupHandler} from "./google-accounts-wakeup-handler.js";
import {RelayGoogleAccessTokens} from "./relay-google-access-tokens.js";
import {HttpRuntimeGoogleRelayClient} from "./runtime-google-relay-client.js";

const license: SignedRuntimeLicense = {
  signature: "sig",
  payload: {licenseId: "l", licenseName: "n", activationId: "a", workspaceId: "w", issuedAt: "2026-01-01", expiresAt: "2027-01-01", maxUsers: 5},
};

function relayIssuing(lifetimeMs: number, now: () => number) {
  const state = {calls: 0};
  return {
    state,
    accessToken: async () => ({accessToken: `token-${++state.calls}`, expiresAt: new Date(now() + lifetimeMs)}),
  };
}

test("ein gültiges Token wird wiederverwendet, gleichzeitige Anfragen teilen sich eine", async () => {
  let now = 0;
  const relay = relayIssuing(3_600_000, () => now);
  const tokens = new RelayGoogleAccessTokens(relay, () => license, () => now);

  assert.deepEqual(await Promise.all([tokens.token("konto"), tokens.token("konto")]), ["token-1", "token-1"]);
  now = 3_000_000;
  assert.equal(await tokens.token("konto"), "token-1");
  assert.equal(relay.state.calls, 1);
});

test("kurz vor Ablauf oder nach invalidate wird ein neues Token geholt", async () => {
  let now = 0;
  const relay = relayIssuing(3_600_000, () => now);
  const tokens = new RelayGoogleAccessTokens(relay, () => license, () => now);

  await tokens.token("konto");
  now = 3_550_000;
  assert.equal(await tokens.token("konto"), "token-2");
  tokens.invalidate("konto");
  assert.equal(await tokens.token("konto"), "token-3");
});

test("ohne Lizenz gibt es kein Token", async () => {
  const tokens = new RelayGoogleAccessTokens(relayIssuing(1, Date.now), () => null);

  await assert.rejects(tokens.token("konto"), /keine aktive Lizenz/);
});

test("409 vom Relay heißt: Konto neu verbinden", async () => {
  const relay = new HttpRuntimeGoogleRelayClient("https://relay.test", async () =>
    Response.json({error: "reauthorization_required"}, {status: 409}));

  await assert.rejects(relay.accessToken(license, "konto"), GoogleReauthorizationRequiredError);
});

test("eine neue Revision leert die Kontenliste und meldet das Realtime-Thema", async () => {
  const cache = new RelayListCache<GoogleAccountSummary>();
  const topics: string[] = [];
  let loads = 0;
  const load = async () => {
    loads += 1;
    return [];
  };
  const handler = new GoogleAccountsWakeupHandler(cache, (topic) => topics.push(topic));

  handler.handle({googleAccountsRevision: 1});
  await cache.list(license, load);
  handler.handle({googleAccountsRevision: 1});
  await cache.list(license, load);
  handler.handle({googleAccountsRevision: 2});
  await cache.list(license, load);

  assert.equal(loads, 2);
  assert.deepEqual(topics, ["google-accounts"]);
});
