import assert from "node:assert/strict";
import test from "node:test";
import {
  adapters, collection, createOrder, order, prepareOrders, search, target, withStore,
} from "./document-store-test-support.js";

for (const adapter of adapters) {
  test(`${adapter.name}: finds one or many documents with safe filters`, async () => {
    await withStore(adapter, async (store) => {
      await prepareOrders(store);
      const order = await store.findOne(search("team-1", "anna@example.com"));
      const paidOrders = await store.findMany({
        teamId: "team-1", collectionId: "bestellungen",
        filters: [{field: "betrag", operator: "greaterThan", value: 100}],
      });

      assert.equal(order?.id, "order-1");
      assert.deepEqual(paidOrders.map((document) => document.id), ["order-2"]);
      assert.equal(await store.findOne(search("team-1", "niemand@example.com")), null);
    });
  });

  test(`${adapter.name}: loads a document by its identity within its collection`, async () => {
    await withStore(adapter, async (store) => {
      await prepareOrders(store);
      const found = await store.findById({
        teamId: "team-1", collectionId: "bestellungen", documentId: "order-1",
      });
      const absent = await store.findById({
        teamId: "team-1", collectionId: "bestellungen", documentId: "order-3",
      });

      assert.equal(found?.data.email, "anna@example.com");
      assert.equal(absent, null);
    });
  });

  test(`${adapter.name}: updates and upserts documents with versions`, async () => {
    await withStore(adapter, async (store) => {
      await prepareOrders(store);
      const first = await store.findOne(search("team-1", "anna@example.com"));
      if (first === null) throw new Error("Der erwartete Datensatz fehlt.");
      const updated = await store.update({...target(first), data: order("bezahlt", 89, "anna@example.com")});
      const newOrder = await store.upsert({
        teamId: "team-1", collectionId: "bestellungen", documentId: "order-3",
        data: order("offen", 49, "cora@example.com"),
      });

      assert.equal(updated.version, 2);
      assert.equal(newOrder.version, 1);
      await assert.rejects(
        () => store.update({...target(updated), expectedVersion: 1, data: updated.data}),
        /inzwischen geändert/,
      );
    });
  });

  test(adapter.name + ": lists, counts, and deletes collection records", async () => {
    await withStore(adapter, async (store) => {
      await prepareOrders(store);
      const collections = await store.listCollections("team-1");
      const first = await store.findOne(search("team-1", "anna@example.com"));
      if (first === null) throw new Error("Der erwartete Datensatz fehlt.");

      assert.equal(collections[0]?.displayName, "Bestellungen");
      assert.equal(await store.countDocuments({teamId: "team-1", collectionId: "bestellungen"}), 2);
      assert.equal(await store.delete({...target(first)}), true);
      assert.equal(await store.delete({...target(first)}), false);
    });
  });

  test(`${adapter.name}: keeps collections and records scoped to their team`, async () => {
    await withStore(adapter, async (store) => {
      await store.createCollection(collection("team-1"));
      await store.createCollection(collection("team-2"));
      await store.create({...createOrder("team-1", "order-1"), data: order("offen", 89, "anna@example.com")});
      await store.create({...createOrder("team-2", "order-1"), data: order("bezahlt", 149, "ben@example.com")});

      assert.equal((await store.findOne(search("team-1", "anna@example.com")))?.data.status, "offen");
      assert.equal(await store.findOne(search("team-1", "ben@example.com")), null);
    });
  });

  test(`${adapter.name}: rejects unsafe input and preserves stored snapshots`, async () => {
    await withStore(adapter, async (store) => {
      await store.createCollection(collection("team-1"));
      const data = order("offen", 89, "anna@example.com");
      await store.create({...createOrder("team-1", "order-1"), data});
      data.status = "bezahlt";

      assert.equal((await store.findOne(search("team-1", "anna@example.com")))?.data.status, "offen");
      await assert.rejects(() => store.findMany({
        teamId: "team-1", collectionId: "bestellungen",
        filters: [{field: "status) OR 1=1 --", operator: "equals", value: "offen"}],
      }), /Datenfelder/);
      await assert.rejects(() => store.create({
        ...createOrder("team-1", "order-2"), data: {wert: undefined as never},
      }), /JSON-kompatibel/);
    });
  });

  test(`${adapter.name}: prevents two parallel updates from using the same version`, async () => {
    await withStore(adapter, async (store) => {
      await prepareOrders(store);
      const current = await store.findOne(search("team-1", "anna@example.com"));
      if (current === null) throw new Error("Der erwartete Datensatz fehlt.");
      const updates = await Promise.allSettled([
        store.update({...target(current), data: order("bezahlt", 89, "anna@example.com")}),
        store.update({...target(current), data: order("storniert", 89, "anna@example.com")}),
      ]);

      assert.equal(updates.filter((update) => update.status === "fulfilled").length, 1);
      assert.equal(updates.filter((update) => update.status === "rejected").length, 1);
      assert.equal((await store.findOne(search("team-1", "anna@example.com")))?.version, 2);
    });
  });
}

