import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type DocumentData, type DocumentRecord, type DocumentValue} from "../../domain/entities/document.js";
import {documentFilterOperators} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {ErrorResponse, ItemsOf, JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";

export type DataRoutesOptions = {store: DocumentStore};

const DocumentDto = Type.Object({id: Type.String(), data: JsonObject, createdAt: Type.String(), updatedAt: Type.String()});
const CollectionDto = Type.Object({
  name: Type.String(), documentCount: Type.Integer(), createdAt: Type.String(), updatedAt: Type.String(),
});
const DocumentQuery = Type.Object({
  search: Type.Optional(Type.String()),
  filters: Type.Optional(Type.Array(Type.Object({
    field: Type.String(),
    operator: Type.Enum(documentFilterOperators),
    value: Type.Union([Type.String(), Type.Number(), Type.Boolean()]),
  }))),
});
const DocumentBody = Type.Object({data: JsonObject});
const CollectionParams = Type.Object({collectionName: NonEmptyString({maxLength: 200})});
const DocumentParams = Type.Object({collectionName: NonEmptyString({maxLength: 200}), documentId: NonEmptyString({maxLength: 200})});
const collectionMissing = {error: "Die Datensammlung wurde nicht gefunden."};

export const dataRoutes: FastifyPluginAsyncTypebox<DataRoutesOptions> = async (app, {store}) => {
  const collectionFor = (teamId: string, displayName: string) => store.findCollectionByName({teamId, displayName});

  app.get("/v1/data/collections", {schema: {response: {200: ItemsOf(CollectionDto)}}}, async (request) => {
    const {teamId} = request.workspace;
    const collections = await store.listCollections(teamId);
    return {items: await Promise.all(collections.map(async (collection) => ({
      name: collection.displayName,
      documentCount: await store.countDocuments({teamId, collectionId: collection.id}),
      createdAt: collection.createdAt.toISOString(), updatedAt: collection.updatedAt.toISOString(),
    })))};
  });

  app.post("/v1/data/collections/:collectionName/query", {
    schema: {params: CollectionParams, body: DocumentQuery, response: {200: ItemsOf(DocumentDto), 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    const documents = await store.findMany({teamId, collectionId: collection.id, filters: request.body.filters ?? [], limit: 500});
    const search = (request.body.search ?? "").trim().toLocaleLowerCase();
    return {items: documents.filter((document) => matchesSearch(document, search)).map(documentDto)};
  });

  app.post("/v1/data/collections/:collectionName/documents", {
    schema: {params: CollectionParams, body: DocumentBody, response: {201: DocumentDto, 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    const created = await store.create({teamId, collectionId: collection.id, data: request.body.data as DocumentData});
    return reply.code(201).send(documentDto(created));
  });

  app.put("/v1/data/collections/:collectionName/documents/:documentId", {
    schema: {params: DocumentParams, body: DocumentBody, response: {200: DocumentDto, 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    const updated = await store.update({teamId, collectionId: collection.id, documentId: request.params.documentId,
      data: request.body.data as DocumentData});
    return documentDto(updated);
  });

  app.delete("/v1/data/collections/:collectionName/documents/:documentId", {
    schema: {params: DocumentParams, response: {204: Type.Null(), 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    const deleted = await store.delete({teamId, collectionId: collection.id, documentId: request.params.documentId});
    return deleted ? reply.code(204).send(null) : reply.code(404).send({error: "Der Datensatz wurde nicht gefunden."});
  });
};

function matchesSearch(document: DocumentRecord, search: string): boolean {
  return search.length === 0 || scalarTexts(document.data).some((value) => value.toLocaleLowerCase().includes(search));
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
