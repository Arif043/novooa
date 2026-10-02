import assert from "node:assert/strict";
import test from "node:test";
import {AccessTokenCache} from "./access-token-cache.js";
import {MailConnectorTokenService, MailReauthorizationRequiredError} from "./mail-connector-token-service.js";
import {invalidGrant, MemoryMailConnectorRepository, ScriptedMailProvider, serverError} from "./mail-connector-test-support.js";

function serviceFor(repository: MemoryMailConnectorRepository, provider: ScriptedMailProvider, clock = {now: 1_000_000}) {
  return new MailConnectorTokenService(repository.asRepository(), provider.asProvider(), new AccessTokenCache(), () => clock.now);
}

test("holt ein Zugriffstoken und speichert das rotierte Refresh Token", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();

  const token = await serviceFor(repository, provider).accessTokenFor(repository.connection());

  assert.equal(token, "access-1");
  assert.deepEqual(provider.refreshCalls, ["refresh-1"]);
  assert.equal(repository.refreshToken, "refresh-2");
});

test("ein noch gültiges Zugriffstoken wird wiederverwendet, ein abgelaufenes erneuert", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const clock = {now: 1_000_000};
  const service = serviceFor(repository, provider, clock);

  await service.accessTokenFor(repository.connection());
  clock.now += 30 * 60_000;
  const cached = await service.accessTokenFor(repository.connection());
  clock.now += 40 * 60_000;
  const renewed = await service.accessTokenFor(repository.connection());

  assert.equal(cached, "access-1");
  assert.equal(renewed, "access-2");
  assert.equal(provider.refreshCalls.length, 2);
});

test("das Zugriffstoken wird kurz vor dem Ablauf nicht mehr verwendet", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const clock = {now: 1_000_000};
  const service = serviceFor(repository, provider, clock);

  await service.accessTokenFor(repository.connection());
  clock.now += 3600_000 - 30_000;
  await service.accessTokenFor(repository.connection());

  assert.equal(provider.refreshCalls.length, 2);
});

test("gleichzeitige Aufrufe teilen sich einen Refresh", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const service = serviceFor(repository, provider);

  const tokens = await Promise.all([1, 2, 3, 4].map(() => service.accessTokenFor(repository.connection())));

  assert.deepEqual(tokens, ["access-1", "access-1", "access-1", "access-1"]);
  assert.equal(provider.refreshCalls.length, 1);
});

test("verschiedene Connectoren teilen weder Cache noch Refresh", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const service = serviceFor(repository, provider);
  const other = {...repository.connection(), connector: {...repository.connection().connector, id: "connector-2"}};

  await service.accessTokenFor(repository.connection());
  await service.accessTokenFor(other);

  assert.equal(provider.refreshCalls.length, 2);
});

test("hat eine andere Instanz das Token rotiert, wird mit dem neuen wiederholt", async () => {
  const repository = new MemoryMailConnectorRepository({refreshToken: "refresh-old"});
  const stale = repository.connection();
  repository.refreshToken = "refresh-rotated-by-other-instance";
  const provider = new ScriptedMailProvider((token, call) =>
    token === "refresh-old" ? invalidGrant() : {accessToken: `access-${call}`, refreshToken: "refresh-newest"});

  const token = await serviceFor(repository, provider).accessTokenFor(stale);

  assert.equal(token, "access-2");
  assert.deepEqual(provider.refreshCalls, ["refresh-old", "refresh-rotated-by-other-instance"]);
  assert.equal(repository.refreshToken, "refresh-newest");
  assert.deepEqual(repository.statusChanges, []);
});

test("ein dauerhaft ungültiges Token setzt den Connector auf „neu verbinden“", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider(() => invalidGrant());
  const service = serviceFor(repository, provider);

  await assert.rejects(service.accessTokenFor(repository.connection()), MailReauthorizationRequiredError);

  assert.equal(repository.status, "reauthorizationRequired");
  assert.deepEqual(repository.statusChanges, ["reauthorizationRequired"]);
  assert.equal(provider.refreshCalls.length, 1, "unverändertes Token wird nicht erneut versucht");
});

test("auch das neu geladene Token kann ungültig sein", async () => {
  const repository = new MemoryMailConnectorRepository({refreshToken: "refresh-old"});
  const stale = repository.connection();
  repository.refreshToken = "refresh-other";
  const provider = new ScriptedMailProvider(() => invalidGrant());

  await assert.rejects(serviceFor(repository, provider).accessTokenFor(stale), MailReauthorizationRequiredError);

  assert.equal(provider.refreshCalls.length, 2);
  assert.equal(repository.status, "reauthorizationRequired");
});

test("vorübergehende Fehler ändern den Status nicht und werden weitergereicht", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider(() => serverError());

  await assert.rejects(serviceFor(repository, provider).accessTokenFor(repository.connection()), /temporarily_unavailable/);

  assert.equal(repository.status, "active");
  assert.deepEqual(repository.statusChanges, []);
});

test("nach einem Fehler startet der nächste Aufruf einen neuen Refresh", async () => {
  const repository = new MemoryMailConnectorRepository();
  let fail = true;
  const provider = new ScriptedMailProvider((_token, call) =>
    fail ? serverError() : {accessToken: `access-${call}`, refreshToken: "refresh-2"});
  const service = serviceFor(repository, provider);

  await assert.rejects(service.accessTokenFor(repository.connection()));
  fail = false;

  assert.equal(await service.accessTokenFor(repository.connection()), "access-2");
});

test("lehnt der Anbieter das gemerkte Token mit 401 ab, wird einmal mit einem frischen wiederholt", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const service = serviceFor(repository, provider);
  const { unauthorized } = await import("./mail-connector-test-support.js");
  const seen: string[] = [];

  const result = await service.withAccessToken(repository.connection(), async (accessToken) => {
    seen.push(accessToken);
    if (seen.length === 1) throw unauthorized();
    return "ok";
  });

  assert.equal(result, "ok");
  assert.deepEqual(seen, ["access-1", "access-2"]);
});

test("ein zweites 401 wird weitergereicht, andere Fehler werden nicht wiederholt", async () => {
  const repository = new MemoryMailConnectorRepository();
  const provider = new ScriptedMailProvider();
  const service = serviceFor(repository, provider);
  const { unauthorized, notFound } = await import("./mail-connector-test-support.js");
  let attempts = 0;

  await assert.rejects(service.withAccessToken(repository.connection(), async () => {
    attempts++;
    throw unauthorized();
  }));
  assert.equal(attempts, 2);

  attempts = 0;
  await assert.rejects(service.withAccessToken(repository.connection(), async () => {
    attempts++;
    throw notFound();
  }));
  assert.equal(attempts, 1);
});
