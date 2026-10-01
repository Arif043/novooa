import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {SQLiteDocumentStore} from "./sqlite-document-store.js";

test("uses exact collection names and hides generated identifiers", async () => {
  await withDocumentStore(async (store) => {
    const first = await store.ensureCollection({teamId: "team-1", displayName: "Kunden"});
    const duplicate = await store.ensureCollection({teamId: "team-1", displayName: "Kunden"});
    const lowercase = await store.ensureCollection({teamId: "team-1", displayName: "kunden"});

    assert.equal(first.id, duplicate.id);
    assert.notEqual(first.id, lowercase.id);
    assert.equal((await store.findCollectionByName({teamId: "team-1", displayName: "Kunden"}))?.id, first.id);
    assert.equal((await store.findCollectionByName({teamId: "team-1", displayName: "kunden"}))?.id, lowercase.id);
  });
});

test("creates documents and finds them through structured filters", async () => {
  await withDocumentStore(async (store) => {
    await store.createCollection(collection("team-1"));
    await store.create({teamId: "team-1", collectionId: "bestellungen", documentId: "order-1", data: order("offen", 89, "anna@example.com")});
    await store.create({teamId: "team-1", collectionId: "bestellungen", documentId: "order-2", data: order("bezahlt", 149, "ben@example.com")});

    const found = await store.findOne({
      teamId: "team-1", collectionId: "bestellungen",
      filters: [{field: "email", operator: "equals", value: "anna@example.com"}],
    });
    const expensiveOrders = await store.findMany({
      teamId: "team-1", collectionId: "bestellungen",
      filters: [
        {field: "status", operator: "equals", value: "bezahlt"},
        {field: "betrag", operator: "greaterThan", value: 100},
      ],
    });

    assert.equal(found?.id, "order-1");
    assert.deepEqual(expensiveOrders.map((document) => document.id), ["order-2"]);
    assert.equal(await store.findOne({
      teamId: "team-1", collectionId: "bestellungen",
      filters: [{field: "email", operator: "equals", value: "unbekannt@example.com"}],
    }), null);
  });
});

test("updates existing documents and upserts missing documents", async () => {
  await withDocumentStore(async (store) => {
    await store.createCollection(collection("team-1"));
    const created = await store.create({
      teamId: "team-1", collectionId: "bestellungen", documentId: "order-1", data: order("offen", 89, "anna@example.com"),
    });
    const updated = await store.update({
      teamId: "team-1", collectionId: "bestellungen", documentId: "order-1", expectedVersion: created.version,
      data: order("bezahlt", 89, "anna@example.com"),
    });
    const upsertedExisting = await store.upsert({
      teamId: "team-1", collectionId: "bestellungen", documentId: "order-1", expectedVersion: updated.version,
      data: order("versendet", 89, "anna@example.com"),
    });
    const upsertedNew = await store.upsert({
      teamId: "team-1", collectionId: "bestellungen", documentId: "order-2", data: order("offen", 49, "ben@example.com"),
    });

    assert.equal(updated.version, 2);
    assert.equal(upsertedExisting.data.status, "versendet");
    assert.equal(upsertedExisting.version, 3);
    assert.equal(upsertedNew.version, 1);
    await assert.rejects(() => store.update({
      teamId: "team-1", collectionId: "bestellungen", documentId: "missing", data: order("offen", 1, "x@example.com"),
    }), /nicht gefunden/);
    await assert.rejects(() => store.update({
      teamId: "team-1", collectionId: "bestellungen", documentId: "order-1", expectedVersion: 1, data: order("offen", 1, "x@example.com"),
    }), /inzwischen geändert/);
  });
});

test("keeps document collections and documents separate per team", async () => {
  await withDocumentStore(async (store) => {
    await store.createCollection(collection("team-1"));
    await store.createCollection(collection("team-2"));
    await store.create({teamId: "team-1", collectionId: "bestellungen", documentId: "order-1", data: order("offen", 89, "anna@example.com")});
    await store.create({teamId: "team-2", collectionId: "bestellungen", documentId: "order-1", data: order("bezahlt", 149, "ben@example.com")});

    const teamOneOrders = await store.findMany({teamId: "team-1", collectionId: "bestellungen"});
    const teamTwoOrders = await store.findMany({teamId: "team-2", collectionId: "bestellungen"});

    assert.equal(teamOneOrders[0]?.data.status, "offen");
    assert.equal(teamTwoOrders[0]?.data.status, "bezahlt");
    await assert.rejects(() => store.update({
      teamId: "team-2", collectionId: "bestellungen", documentId: "missing", data: order("offen", 1, "x@example.com"),
    }), /nicht gefunden/);
  });
});

test("rejects unsafe fields and invalid document values", async () => {
  await withDocumentStore(async (store) => {
    await store.createCollection(collection("team-1"));
    await assert.rejects(() => store.findMany({
      teamId: "team-1", collectionId: "bestellungen",
      filters: [{field: "status) OR 1=1 --", operator: "equals", value: "offen"}],
    }), /Datenfelder/);
    await assert.rejects(() => store.create({
      teamId: "team-1", collectionId: "bestellungen", documentId: "order-1",
      data: {"ungültiges-feld": "Wert"},
    }), /Datenfelder/);
    await assert.rejects(() => store.findMany({
      teamId: "team-1", collectionId: "bestellungen",
      filters: [{field: "betrag", operator: "greaterThan", value: "100"}],
    }), /Numerische Datenfilter/);
  });
});

function collection(teamId: string) {
  return {teamId, id: "bestellungen", displayName: "Bestellungen"};
}

function order(status: string, betrag: number, email: string) {
  return {status, betrag, email};
}

async function withDocumentStore(operation: (store: DocumentStore) => Promise<void>): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-document-store-"));
  const database = await openLocalRuntimeDatabase({
    databasePath: join(directory, "novooa.sqlite"),
    migrationsDirectory,
  });
  try {
    await database.run(sql`INSERT INTO teams(id, name, owner_uid) VALUES (${"team-1"}, ${"Team eins"}, ${"user-1"})`);
    await database.run(sql`INSERT INTO teams(id, name, owner_uid) VALUES (${"team-2"}, ${"Team zwei"}, ${"user-2"})`);
    await operation(new SQLiteDocumentStore(database));
  } finally {
    database.$client.close();
    await rm(directory, {force: true, recursive: true});
  }
}

const migrationsDirectory = resolve(__dirname, "../../../../../drizzle");
