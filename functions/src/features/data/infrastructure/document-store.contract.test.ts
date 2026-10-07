import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../db/database.js";
import {type DocumentStore} from "../domain/repositories/document-store.js";
import {InMemoryDocumentStore} from "./in-memory/in-memory-document-store.js";
import {SQLiteDocumentStore} from "./local/sqlite-document-store.js";

type StoreFixture = {
  store: DocumentStore;
  dispose: () => void;
};

type StoreAdapter = {
  name: string;
  create: () => Promise<StoreFixture>;
};

const adapters: readonly StoreAdapter[] = [
  {name: "InMemoryDocumentStore", create: createInMemoryFixture},
  {name: "SQLiteDocumentStore", create: createSQLiteFixture},
];

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

async function withStore(adapter: StoreAdapter, operation: (store: DocumentStore) => Promise<void>): Promise<void> {
  const fixture = await adapter.create();
  try {
    await operation(fixture.store);
  } finally {
    fixture.dispose();
  }
}

async function createInMemoryFixture(): Promise<StoreFixture> {
  return {store: new InMemoryDocumentStore(), dispose: () => undefined};
}

async function createSQLiteFixture(): Promise<StoreFixture> {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE document_collections (id TEXT, team_id TEXT, display_name TEXT, created_at TEXT, updated_at TEXT, PRIMARY KEY (team_id, id), UNIQUE(team_id, display_name))`);
  await database.run(sql`CREATE TABLE documents (id TEXT, team_id TEXT, collection_id TEXT, data_json TEXT, version INTEGER, created_at TEXT, updated_at TEXT, PRIMARY KEY (team_id, collection_id, id))`);
  return {store: new SQLiteDocumentStore(database), dispose: () => database.$client.close()};
}

async function prepareOrders(store: DocumentStore): Promise<void> {
  await store.createCollection(collection("team-1"));
  await store.create({...createOrder("team-1", "order-1"), data: order("offen", 89, "anna@example.com")});
  await store.create({...createOrder("team-1", "order-2"), data: order("bezahlt", 149, "ben@example.com")});
}

function collection(teamId: string) {
  return {teamId, id: "bestellungen", displayName: "Bestellungen"};
}

function createOrder(teamId: string, documentId: string) {
  return {teamId, collectionId: "bestellungen", documentId};
}

function search(teamId: string, email: string) {
  return {teamId, collectionId: "bestellungen", filters: [{field: "email", operator: "equals" as const, value: email}]};
}

function target(document: {teamId: string; collectionId: string; id: string; version: number}) {
  return {teamId: document.teamId, collectionId: document.collectionId, documentId: document.id, expectedVersion: document.version};
}

function order(status: string, betrag: number, email: string) {
  return {status, betrag, email};
}
