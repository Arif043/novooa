import { type FastifyInstance, type FastifyReply } from "fastify";
import { type DocumentData, type DocumentRecord, type DocumentValue, } from "../../domain/entities/document.js";
import { type DocumentFilter, type DocumentFilterOperator, documentFilterOperators, } from "../../domain/entities/document-filter.js";
import { type DocumentStore } from "../../domain/repositories/document-store.js";
export class LocalDataHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalDataHttpHandler): void {
    http.get("/v1/data/collections", (request, reply) => current().list(reply));
    http.post<{
      Params: {
        collectionName: string;
      };
    }>("/v1/data/collections/:collectionName/query", (request, reply) => current().query(request.params.collectionName, request.body, reply));
    http.post<{
      Params: {
        collectionName: string;
      };
    }>("/v1/data/collections/:collectionName/documents", (request, reply) => current().create(request.params.collectionName, request.body, reply));
    http.put<{
      Params: {
        collectionName: string;
        documentId: string;
      };
    }>("/v1/data/collections/:collectionName/documents/:documentId", (request, reply) => current().update(targetOf(request.params), request.body, reply));
    http.delete<{
      Params: {
        collectionName: string;
        documentId: string;
      };
    }>("/v1/data/collections/:collectionName/documents/:documentId", (request, reply) => current().remove(targetOf(request.params), reply));
  }
  constructor(private readonly store: DocumentStore, private readonly teamId: string) { }
  private async list(reply: FastifyReply): Promise<FastifyReply> {
    const collections = await this.store.listCollections(this.teamId);
    const items = await Promise.all(collections.map(async (collection) => ({
      name: collection.displayName,
      documentCount: await this.store.countDocuments({ teamId: this.teamId, collectionId: collection.id }),
      createdAt: collection.createdAt.toISOString(),
      updatedAt: collection.updatedAt.toISOString(),
    })));
    return reply.code(200).send({ items });
  }
  private async query(collectionName: string, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    const collection = await this.collection(collectionName);
    if (collection === null)
      return reply.code(404).send({ error: "Die Datensammlung wurde nicht gefunden." });
    const input = queryFrom(body);
    const documents = await this.store.findMany({ teamId: this.teamId, collectionId: collection.id, filters: input.filters, limit: 500 });
    return reply.code(200).send({ items: documents.filter((document) => matchesSearch(document, input.search)).map(documentDto) });
  }
  private async create(collectionName: string, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    const collection = await this.collection(collectionName);
    if (collection === null)
      return reply.code(404).send({ error: "Die Datensammlung wurde nicht gefunden." });
    const created = await this.store.create({ teamId: this.teamId, collectionId: collection.id, data: dataFrom(body) });
    return reply.code(201).send(documentDto(created));
  }
  private async update(target: DocumentTarget, body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    const collection = await this.collection(target.collectionName);
    if (collection === null)
      return reply.code(404).send({ error: "Die Datensammlung wurde nicht gefunden." });
    const updated = await this.store.update({ teamId: this.teamId, collectionId: collection.id, documentId: target.documentId, data: dataFrom(body) });
    return reply.code(200).send(documentDto(updated));
  }
  private async remove(target: DocumentTarget, reply: FastifyReply): Promise<FastifyReply> {
    const collection = await this.collection(target.collectionName);
    if (collection === null)
      return reply.code(404).send({ error: "Die Datensammlung wurde nicht gefunden." });
    const deleted = await this.store.delete({ teamId: this.teamId, collectionId: collection.id, documentId: target.documentId });
    return deleted ? reply.code(204).send() : reply.code(404).send({ error: "Der Datensatz wurde nicht gefunden." });
  }
  private collection(displayName: string) {
    return this.store.findCollectionByName({ teamId: this.teamId, displayName });
  }
}
type QueryInput = {
  filters: DocumentFilter[];
  search: string;
};
type DocumentTarget = {
  kind: "document";
  collectionName: string;
  documentId: string;
};
function targetOf(params: {
  collectionName: string;
  documentId: string;
}): DocumentTarget {
  return { kind: "document", ...params };
}
function queryFrom(body: unknown): QueryInput {
  const value = record(body);
  return { filters: filtersFrom(value.filters), search: typeof value.search === "string" ? value.search.trim().toLocaleLowerCase() : "" };
}
function dataFrom(body: unknown): DocumentData {
  const value = record(body);
  const data = record(value.data);
  return data as DocumentData;
}
function filtersFrom(value: unknown): DocumentFilter[] {
  if (value === undefined)
    return [];
  if (!Array.isArray(value))
    throw new Error("Die Filter sind ungültig.");
  return value.map(filterFrom);
}
function filterFrom(value: unknown): DocumentFilter {
  const filter = record(value);
  const operator = filter.operator;
  if (typeof filter.field !== "string" || !documentFilterOperators.includes(operator as DocumentFilterOperator))
    throw new Error("Der Filter ist ungültig.");
  if (!isFilterValue(filter.value))
    throw new Error("Der Filterwert ist ungültig.");
  return { field: filter.field, operator: operator as DocumentFilterOperator, value: filter.value };
}
function isFilterValue(value: unknown): value is string | number | boolean {
  return typeof value === "string" || typeof value === "boolean" || (typeof value === "number" && Number.isFinite(value));
}
function matchesSearch(document: DocumentRecord, search: string): boolean {
  if (search.length === 0)
    return true;
  return scalarTexts(document.data).some((value) => value.toLocaleLowerCase().includes(search));
}
function scalarTexts(value: DocumentValue): string[] {
  if (value === null)
    return ["null"];
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean")
    return [String(value)];
  if (Array.isArray(value))
    return value.flatMap(scalarTexts);
  return Object.values(value).flatMap(scalarTexts);
}
function documentDto(document: DocumentRecord) {
  return { id: document.id, data: document.data, createdAt: document.createdAt.toISOString(), updatedAt: document.updatedAt.toISOString() };
}
function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value))
    return value as Record<string, unknown>;
  throw new Error("Die Anfrage ist ungültig.");
}
