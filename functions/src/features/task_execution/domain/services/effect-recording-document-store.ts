import {type DocumentStore} from "../../../data/domain/repositories/document-store.js";
import {type RunEffectRecorder} from "./run-effect-recorder.js";

type Store = DocumentStore;

/**
 * Datensammlungen mit Effekten: Anlegen, Ändern und Löschen von Datensätzen werden
 * aufgezeichnet, Lesen und die Verwaltung von Sammlungen nicht.
 */
export class EffectRecordingDocumentStore implements DocumentStore {
  constructor(private readonly inner: Store, private readonly effects: RunEffectRecorder) {}

  createCollection: Store["createCollection"] = (input) => this.inner.createCollection(input);
  ensureCollection: Store["ensureCollection"] = (input) => this.inner.ensureCollection(input);
  findCollectionByName: Store["findCollectionByName"] = (input) => this.inner.findCollectionByName(input);
  listCollections: Store["listCollections"] = (teamId) => this.inner.listCollections(teamId);
  renameCollection: Store["renameCollection"] = (input) => this.inner.renameCollection(input);
  deleteCollection: Store["deleteCollection"] = (input) => this.inner.deleteCollection(input);
  countDocuments: Store["countDocuments"] = (input) => this.inner.countDocuments(input);
  findById: Store["findById"] = (input) => this.inner.findById(input);
  findOne: Store["findOne"] = (input) => this.inner.findOne(input);
  findMany: Store["findMany"] = (input) => this.inner.findMany(input);

  create: Store["create"] = async (input) => {
    const record = await this.inner.create(input);
    this.changed(record.collectionId, "created", 1, record.id);
    return record;
  };

  createMany: Store["createMany"] = async (input) => {
    const count = await this.inner.createMany(input);
    if (count > 0) this.changed(input.collectionId, "created", count);
    return count;
  };

  update: Store["update"] = async (input) => {
    const record = await this.inner.update(input);
    this.changed(record.collectionId, "updated", 1, record.id);
    return record;
  };

  upsert: Store["upsert"] = async (input) => {
    const record = await this.inner.upsert(input);
    // Version 1 heißt: Der Datensatz ist gerade erst entstanden.
    this.changed(record.collectionId, record.version === 1 ? "created" : "updated", 1, record.id);
    return record;
  };

  delete: Store["delete"] = async (input) => {
    const deleted = await this.inner.delete(input);
    if (deleted) this.changed(input.collectionId, "deleted", 1, input.documentId);
    return deleted;
  };

  deleteDocuments: Store["deleteDocuments"] = async (input) => {
    const count = await this.inner.deleteDocuments(input);
    if (count > 0) this.changed(input.collectionId, "deleted", count);
    return count;
  };

  private changed(collectionId: string, operation: "created" | "updated" | "deleted", count: number, documentId?: string) {
    this.effects.record({kind: "recordsChanged", collectionId, operation, count, ...(documentId ? {documentId} : {})});
  }
}
