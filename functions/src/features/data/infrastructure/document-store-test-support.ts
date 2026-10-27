import {sql} from "drizzle-orm";
import {connectRuntimeDatabase} from "../../../db/database.js";
import {type DocumentStore} from "../domain/repositories/document-store.js";
import {InMemoryDocumentStore} from "./in-memory/in-memory-document-store.js";
import {SQLiteDocumentStore} from "./local/sqlite-document-store.js";

/** Nur Tests: beide Store-Adapter für die gemeinsamen Vertragstests. */
export type StoreFixture = {
  store: DocumentStore;
  dispose: () => void;
};

export type StoreAdapter = {
  name: string;
  create: () => Promise<StoreFixture>;
};

export const adapters: readonly StoreAdapter[] = [
  {name: "InMemoryDocumentStore", create: createInMemoryFixture},
  {name: "SQLiteDocumentStore", create: createSQLiteFixture},
];


export async function withStore(adapter: StoreAdapter, operation: (store: DocumentStore) => Promise<void>): Promise<void> {
  const fixture = await adapter.create();
  try {
    await operation(fixture.store);
  } finally {
    fixture.dispose();
  }
}

export async function createInMemoryFixture(): Promise<StoreFixture> {
  return {store: new InMemoryDocumentStore(), dispose: () => undefined};
}

export async function createSQLiteFixture(): Promise<StoreFixture> {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE document_collections (id TEXT, team_id TEXT, display_name TEXT, created_at TEXT, updated_at TEXT, PRIMARY KEY (team_id, id), UNIQUE(team_id, display_name))`);
  await database.run(sql`CREATE TABLE documents (id TEXT, team_id TEXT, collection_id TEXT, data_json TEXT, version INTEGER, created_at TEXT, updated_at TEXT, PRIMARY KEY (team_id, collection_id, id))`);
  return {store: new SQLiteDocumentStore(database), dispose: () => database.$client.close()};
}

export async function prepareOrders(store: DocumentStore): Promise<void> {
  await store.createCollection(collection("team-1"));
  await store.create({...createOrder("team-1", "order-1"), data: order("offen", 89, "anna@example.com")});
  await store.create({...createOrder("team-1", "order-2"), data: order("bezahlt", 149, "ben@example.com")});
}

export function collection(teamId: string) {
  return {teamId, id: "bestellungen", displayName: "Bestellungen"};
}

export function createOrder(teamId: string, documentId: string) {
  return {teamId, collectionId: "bestellungen", documentId};
}

export function search(teamId: string, email: string) {
  return {teamId, collectionId: "bestellungen", filters: [{field: "email", operator: "equals" as const, value: email}]};
}

export function target(document: {teamId: string; collectionId: string; id: string; version: number}) {
  return {teamId: document.teamId, collectionId: document.collectionId, documentId: document.id, expectedVersion: document.version};
}

export function order(status: string, betrag: number, email: string) {
  return {status, betrag, email};
}
