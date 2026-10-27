import assert from "node:assert/strict";
import test from "node:test";
import {DocumentCollectionNameTakenError} from "../domain/entities/document-collection.js";
import {type DocumentStore} from "../domain/repositories/document-store.js";
import {adapters, withStore} from "./document-store-test-support.js";

const kunden = {teamId: "team-1", collectionId: "kunden"};

for (const adapter of adapters) {
  test(`${adapter.name}: renames a collection and refuses a name another collection holds`, async () => {
    await withStore(adapter, async (store) => {
      await store.createCollection({teamId: "team-1", id: "kunden", displayName: "Kunden"});
      await store.createCollection({teamId: "team-1", id: "lieferanten", displayName: "Lieferanten"});
      await store.createCollection({teamId: "team-2", id: "fremd", displayName: "Partner"});

      const renamed = await store.renameCollection({...kunden, displayName: "Partner"});
      const unchanged = await store.renameCollection({...kunden, displayName: "Partner"});

      assert.equal(renamed?.displayName, "Partner", "Namen gelten je Team");
      assert.equal(unchanged?.displayName, "Partner", "der eigene Name ist kein Konflikt");
      await assert.rejects(store.renameCollection({teamId: "team-1", collectionId: "lieferanten", displayName: "Partner"}),
        DocumentCollectionNameTakenError);
      assert.equal(await store.renameCollection({teamId: "team-1", collectionId: "fehlt", displayName: "X"}), null);
      assert.equal((await store.findCollectionByName({teamId: "team-1", displayName: "Kunden"})), null);
    });
  });

  test(`${adapter.name}: deletes a collection together with its documents only`, async () => {
    await withStore(adapter, async (store) => {
      await prepareCustomers(store, 3);
      await store.createCollection({teamId: "team-1", id: "andere", displayName: "Andere"});
      await store.create({teamId: "team-1", collectionId: "andere", data: {name: "bleibt"}});

      assert.equal(await store.deleteCollection(kunden), true);
      assert.equal(await store.deleteCollection(kunden), false);
      assert.equal(await store.countDocuments(kunden), 0);
      assert.deepEqual((await store.listCollections("team-1")).map((item) => item.displayName), ["Andere"]);
      assert.equal(await store.countDocuments({teamId: "team-1", collectionId: "andere"}), 1);
    });
  });

  test(`${adapter.name}: deletes chosen documents or clears the whole collection`, async () => {
    await withStore(adapter, async (store) => {
      await prepareCustomers(store, 4);
      const [first, second] = await store.findMany({...kunden, sort: {field: "nummer", direction: "asc"}});

      const chosen = await store.deleteDocuments({...kunden, documentIds: [first.id, second.id, "unbekannt"]});
      const foreign = await store.deleteDocuments({teamId: "team-2", collectionId: "kunden"});
      const empty = await store.deleteDocuments({...kunden, documentIds: []});
      const cleared = await store.deleteDocuments(kunden);

      assert.deepEqual([chosen, foreign, empty, cleared], [2, 0, 0, 2]);
      assert.notEqual(await store.findCollectionByName({teamId: "team-1", displayName: "Kunden"}), null, "Leeren behält die Sammlung");
    });
  });

  test(`${adapter.name}: creates many documents at once or none when one is invalid`, async () => {
    await withStore(adapter, async (store) => {
      await store.createCollection({teamId: "team-1", id: "kunden", displayName: "Kunden"});

      const created = await store.createMany({...kunden, items: [{name: "A"}, {name: "B", tags: ["x"]}]});
      await assert.rejects(store.createMany({...kunden, items: [{name: "C"}, ["kein Objekt"] as never]}));
      await assert.rejects(store.createMany({teamId: "team-1", collectionId: "fehlt", items: [{name: "D"}]}));

      assert.equal(created, 2);
      assert.equal(await store.countDocuments(kunden), 2);
    });
  });

  test(`${adapter.name}: sorts by a field with missing values last and pages with offset`, async () => {
    await withStore(adapter, async (store) => {
      await store.createCollection({teamId: "team-1", id: "kunden", displayName: "Kunden"});
      await store.createMany({...kunden, items: [
        {name: "beta", wert: 10}, {name: "Alpha", wert: 2}, {name: "gamma"}, {name: "delta", wert: "zehn"}, {wert: 5},
      ]});

      const names = async (direction: "asc" | "desc", offset = 0, limit = 10) =>
        (await store.findMany({...kunden, sort: {field: "wert", direction}, offset, limit})).map((item) => item.data.name ?? "-");
      const byName = (await store.findMany({...kunden, sort: {field: "name", direction: "asc"}})).map((item) => item.data.name ?? "-");

      assert.deepEqual(await names("asc"), ["Alpha", "-", "beta", "delta", "gamma"], "Zahlen vor Text, fehlend zuletzt");
      assert.deepEqual(await names("desc"), ["beta", "-", "Alpha", "delta", "gamma"], "fehlend bleibt zuletzt");
      assert.deepEqual(await names("asc", 1, 2), ["-", "beta"]);
      assert.deepEqual(byName, ["Alpha", "beta", "delta", "gamma", "-"], "Text ohne Groß-/Kleinschreibung");
    });
  });
}

async function prepareCustomers(store: DocumentStore, count: number): Promise<void> {
  await store.createCollection({teamId: "team-1", id: "kunden", displayName: "Kunden"});
  await store.createMany({...kunden, items: Array.from({length: count}, (_, index) => ({nummer: index + 1}))});
}
