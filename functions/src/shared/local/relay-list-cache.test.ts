import assert from "node:assert/strict";
import test from "node:test";
import {type SignedRuntimeLicense} from "../../features/licensing/domain/entities/runtime-license-lease.js";
import {RelayListCache} from "./relay-list-cache.js";

type Item = {id: string};

function licenseOf(licenseId: string): SignedRuntimeLicense {
  return {
    signature: "sig",
    payload: {licenseId, licenseName: "n", activationId: "a", workspaceId: "w", issuedAt: "2026-01-01", expiresAt: "2027-01-01", maxUsers: 5},
  };
}

function summary(id: string): Item {
  return {id};
}

function countingLoader(...lists: Item[][]) {
  const state = {calls: 0};
  return {
    state,
    load: async () => lists[Math.min(state.calls++, lists.length - 1)],
  };
}

test("lädt die Liste einmal aus der Cloud und bedient weitere Anfragen aus dem Cache", async () => {
  const cache = new RelayListCache<Item>();
  const loader = countingLoader([summary("a")]);

  await cache.list(licenseOf("l"), loader.load);
  const second = await cache.list(licenseOf("l"), loader.load);

  assert.equal(loader.state.calls, 1);
  assert.equal(second[0].id, "a");
});

test("nach invalidate wird die Liste neu aus der Cloud geladen", async () => {
  const cache = new RelayListCache<Item>();
  const loader = countingLoader([summary("a")], [summary("b")]);

  await cache.list(licenseOf("l"), loader.load);
  cache.invalidate();
  const reloaded = await cache.list(licenseOf("l"), loader.load);

  assert.equal(loader.state.calls, 2);
  assert.equal(reloaded[0].id, "b");
});

test("eine andere Lizenz bekommt nie die Liste einer fremden", async () => {
  const cache = new RelayListCache<Item>();
  const loader = countingLoader([summary("a")], [summary("b")]);

  await cache.list(licenseOf("l1"), loader.load);
  const other = await cache.list(licenseOf("l2"), loader.load);

  assert.equal(other[0].id, "b");
});

test("ein Fehlschlag wird nicht gecacht", async () => {
  const cache = new RelayListCache<Item>();
  let calls = 0;
  const load = async () => {
    calls++;
    if (calls === 1) throw new Error("Cloud nicht erreichbar");
    return [summary("a")];
  };

  await assert.rejects(cache.list(licenseOf("l"), load), /Cloud nicht erreichbar/);
  const retry = await cache.list(licenseOf("l"), load);

  assert.equal(calls, 2);
  assert.equal(retry[0].id, "a");
});

test("ein während des Ladens eintreffendes Ereignis verhindert das Festhalten des alten Stands", async () => {
  const cache = new RelayListCache<Item>();
  const first = cache.list(licenseOf("l"), async () => [summary("alt")]);
  cache.invalidate();
  const loader = countingLoader([summary("neu")]);

  await first;
  const fresh = await cache.list(licenseOf("l"), loader.load);

  assert.equal(fresh[0].id, "neu");
});
