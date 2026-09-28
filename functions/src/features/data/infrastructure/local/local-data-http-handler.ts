import {
  type DocumentData,
  type DocumentRecord,
  type DocumentValue,
} from "../../domain/entities/document.js";
import {
  type DocumentFilter,
  type DocumentFilterOperator,
  documentFilterOperators,
} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {routeMatch} from "../../../../shared/local/local-runtime-route.js";

export class LocalDataHttpHandler implements LocalRuntimeRequestHandler {
  constructor(private readonly store: DocumentStore, private readonly teamId: string) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (routeMatch(request, "GET", "/v1/data/collections")) return this.list();
    const collections = "/v1/data/collections/:collectionName";
    const documents = `${collections}/documents` as const;
    const document = `${documents}/:documentId` as const;
    try {
      const query = routeMatch(request, "POST", `${collections}/query` as const);
      if (query) return this.query(query.params.collectionName, request.body);
      const created = routeMatch(request, "POST", documents);
      if (created) return this.create(created.params.collectionName, request.body);
      const updated = routeMatch(request, "PUT", document);
      if (updated) return this.update(targetOf(updated.params), request.body);
      const removed = routeMatch(request, "DELETE", document);
      if (removed) return this.remove(targetOf(removed.params));
      return null;
    } catch (error) {
      return {body: {error: messageFor(error)}, statusCode: 400};
    }
  }

  private async list(): Promise<LocalRuntimeResponse> {
    const collections = await this.store.listCollections(this.teamId);
    const items = await Promise.all(collections.map(async (collection) => ({
      name: collection.displayName,
      documentCount: await this.store.countDocuments({teamId: this.teamId, collectionId: collection.id}),
      createdAt: collection.createdAt.toISOString(),
      updatedAt: collection.updatedAt.toISOString(),
    })));
    return {body: {items}, statusCode: 200};
  }

  private async query(collectionName: string, body: unknown): Promise<LocalRuntimeResponse> {
    const collection = await this.collection(collectionName);
    if (collection === null) return {body: {error: "Die Datensammlung wurde nicht gefunden."}, statusCode: 404};
    const input = queryFrom(body);
    const documents = await this.store.findMany({teamId: this.teamId, collectionId: collection.id, filters: input.filters, limit: 500});
    return {body: {items: documents.filter((document) => matchesSearch(document, input.search)).map(documentDto)}, statusCode: 200};
  }

  private async create(collectionName: string, body: unknown): Promise<LocalRuntimeResponse> {
    const collection = await this.collection(collectionName);
    if (collection === null) return {body: {error: "Die Datensammlung wurde nicht gefunden."}, statusCode: 404};
    const created = await this.store.create({teamId: this.teamId, collectionId: collection.id, data: dataFrom(body)});
    return {body: documentDto(created), statusCode: 201};
  }

  private async update(target: DocumentTarget, body: unknown): Promise<LocalRuntimeResponse> {
    const collection = await this.collection(target.collectionName);
    if (collection === null) return {body: {error: "Die Datensammlung wurde nicht gefunden."}, statusCode: 404};
    const updated = await this.store.update({teamId: this.teamId, collectionId: collection.id, documentId: target.documentId, data: dataFrom(body)});
    return {body: documentDto(updated), statusCode: 200};
  }

  private async remove(target: DocumentTarget): Promise<LocalRuntimeResponse> {
    const collection = await this.collection(target.collectionName);
    if (collection === null) return {body: {error: "Die Datensammlung wurde nicht gefunden."}, statusCode: 404};
    const deleted = await this.store.delete({teamId: this.teamId, collectionId: collection.id, documentId: target.documentId});
    return deleted ? {body: {}, statusCode: 204} : {body: {error: "Der Datensatz wurde nicht gefunden."}, statusCode: 404};
  }

  private collection(displayName: string) {
    return this.store.findCollectionByName({teamId: this.teamId, displayName});
  }
}

type QueryInput = {filters: DocumentFilter[]; search: string};
type DocumentTarget = {kind: "document"; collectionName: string; documentId: string};

function targetOf(params: {collectionName: string; documentId: string}): DocumentTarget {
  return {kind: "document", ...params};
}


function queryFrom(body: unknown): QueryInput {
  const value = record(body);
  return {filters: filtersFrom(value.filters), search: typeof value.search === "string" ? value.search.trim().toLocaleLowerCase() : ""};
}

function dataFrom(body: unknown): DocumentData {
  const value = record(body);
  const data = record(value.data);
  return data as DocumentData;
}

function filtersFrom(value: unknown): DocumentFilter[] {
  if (value === undefined) return [];
  if (!Array.isArray(value)) throw new Error("Die Filter sind ungültig.");
  return value.map(filterFrom);
}

function filterFrom(value: unknown): DocumentFilter {
  const filter = record(value);
  const operator = filter.operator;
  if (typeof filter.field !== "string" || !documentFilterOperators.includes(operator as DocumentFilterOperator)) throw new Error("Der Filter ist ungültig.");
  if (!isFilterValue(filter.value)) throw new Error("Der Filterwert ist ungültig.");
  return {field: filter.field, operator: operator as DocumentFilterOperator, value: filter.value};
}

function isFilterValue(value: unknown): value is string | number | boolean {
  return typeof value === "string" || typeof value === "boolean" || (typeof value === "number" && Number.isFinite(value));
}

function matchesSearch(document: DocumentRecord, search: string): boolean {
  if (search.length === 0) return true;
  return scalarTexts(document.data).some((value) => value.toLocaleLowerCase().includes(search));
}

function scalarTexts(value: DocumentValue): string[] {
  if (value === null) return ["null"];
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") return [String(value)];
  if (Array.isArray(value)) return value.flatMap(scalarTexts);
  return Object.values(value).flatMap(scalarTexts);
}

function documentDto(document: DocumentRecord) {
  return {id: document.id, data: document.data, createdAt: document.createdAt.toISOString(), updatedAt: document.updatedAt.toISOString()};
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Die Anfrage ist ungültig.");
}

function messageFor(error: unknown): string {
  return error instanceof Error ? error.message : "Die Daten konnten nicht verarbeitet werden.";
}
