import assert from "node:assert/strict";
import test from "node:test";
import {GoogleAuthorizationRevokedError} from "../repositories/google-oauth-provider.js";
import {IssueGoogleAccessToken} from "./issue-google-access-token.js";
import {
  FakeGoogleOAuthProvider,
  MemoryGoogleAccountRepository,
  storedAccount,
} from "./google-account-test-support.js";

const now = new Date("2026-10-25T10:00:00Z");
const request = {teamId: "team-1", runtimeLicenseId: "lizenz-1", accountId: "konto-1"};

test("die eigene Runtime bekommt ein frisches Zugriffstoken mit Ablaufzeit", async () => {
  const issuer = new IssueGoogleAccessToken(new MemoryGoogleAccountRepository(storedAccount()), new FakeGoogleOAuthProvider(), () => now);

  const token = await issuer.execute(request);

  assert.equal(token.accessToken, "access-frisch");
  assert.deepEqual(token.expiresAt, new Date(now.getTime() + 3599 * 1000));
});

test("eine fremde Runtime bekommt kein Token", async () => {
  const issuer = new IssueGoogleAccessToken(new MemoryGoogleAccountRepository(storedAccount()), new FakeGoogleOAuthProvider());

  await assert.rejects(issuer.execute({...request, runtimeLicenseId: "lizenz-2"}), /gehört nicht zu dieser Runtime/);
});

test("zieht Google die Anmeldung zurück, muss das Konto neu verbunden werden", async () => {
  const repository = new MemoryGoogleAccountRepository(storedAccount());
  const provider = new FakeGoogleOAuthProvider();
  provider.refresh = () => Promise.reject(new GoogleAuthorizationRevokedError());

  await assert.rejects(new IssueGoogleAccessToken(repository, provider).execute(request), GoogleAuthorizationRevokedError);
  assert.deepEqual(repository.statuses, ["reauthorizationRequired"]);
});

test("vorübergehende Fehler ändern den Status nicht", async () => {
  const repository = new MemoryGoogleAccountRepository(storedAccount());
  const provider = new FakeGoogleOAuthProvider();
  provider.refresh = () => Promise.reject(new Error("Netzwerk"));

  await assert.rejects(new IssueGoogleAccessToken(repository, provider).execute(request), /Netzwerk/);
  assert.deepEqual(repository.statuses, []);
});
