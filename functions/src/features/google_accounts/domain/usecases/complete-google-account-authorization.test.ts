import assert from "node:assert/strict";
import test from "node:test";
import {completeGoogleAccountAuthorization} from "./complete-google-account-authorization.js";
import {
  FakeGoogleOAuthProvider,
  MemoryGoogleAccountRepository,
  storedAccount,
} from "./google-account-test-support.js";

function inputWith(repository: MemoryGoogleAccountRepository, provider = new FakeGoogleOAuthProvider()) {
  return {
    authorizationId: "anmeldung-1", authorizationCode: "code", pickedItemIds: ["datei-1"],
    newAccountId: "neue-id", repository, provider, now: new Date("2026-10-25T10:00:00Z"),
  };
}

test("ein neues Konto gehört der Lizenz der Anmeldung und bekommt die gewählten Freigaben", async () => {
  const repository = new MemoryGoogleAccountRepository();
  const account = await completeGoogleAccountAuthorization(inputWith(repository));

  assert.equal(account.id, "neue-id");
  assert.equal(account.runtimeLicenseId, "lizenz-1");
  assert.equal(account.email, "neu@example.com");
  assert.deepEqual(account.sharedItems.map((item) => item.id), ["datei-1"]);
  assert.equal(repository.saved[0].refreshToken, "refresh-neu");
});

test("erneutes Verbinden behält ID und Freigaben und ergänzt neue", async () => {
  const repository = new MemoryGoogleAccountRepository(storedAccount({status: "reauthorizationRequired"}));
  const account = await completeGoogleAccountAuthorization(inputWith(repository));

  assert.equal(account.id, "konto-1");
  assert.equal(account.status, "active");
  assert.equal(account.email, "neu@example.com");
  assert.deepEqual(account.sharedItems.map((item) => item.id), ["ordner-1", "datei-1"]);
  assert.deepEqual(account.createdAt, new Date("2026-01-01T00:00:00Z"));
});

test("eine verbrauchte oder unbekannte Anmeldung wird abgelehnt", async () => {
  const repository = new MemoryGoogleAccountRepository();
  repository.authorization = null;

  await assert.rejects(completeGoogleAccountAuthorization(inputWith(repository)), /ungültig oder abgelaufen/);
  assert.equal(repository.saved.length, 0);
});

test("ohne Refresh-Token wird nichts gespeichert", async () => {
  const repository = new MemoryGoogleAccountRepository();
  const provider = new FakeGoogleOAuthProvider();
  provider.grant = {accessToken: "access", expiresInSeconds: 3600};

  await assert.rejects(completeGoogleAccountAuthorization(inputWith(repository, provider)), /Refresh-Token/);
  assert.equal(repository.saved.length, 0);
});
