import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type DocumentData, maximumDocumentIdsPerDelete} from "../../domain/entities/document.js";
import {ErrorResponse, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {
  CollectionParams, collectionMissing, type DataRoutesOptions, DeletedCount, DocumentBody, DocumentDto, DocumentParams,
  DocumentQuery, documentDto, matchesSearch,
} from "./local-data-route-schemas.js";

/** Datensätze einer Sammlung suchen, anlegen, ändern und löschen — einzeln, ausgewählt oder alle. */
export const dataDocumentRoutes: FastifyPluginAsyncTypebox<DataRoutesOptions> = async (app, {store}) => {
  const collectionFor = (teamId: string, displayName: string) => store.findCollectionByName({teamId, displayName});

  app.post("/v1/data/collections/:collectionName/query", {
    schema: {params: CollectionParams, body: DocumentQuery, response: {200: ItemsOf(DocumentDto), 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    const documents = await store.findMany({teamId, collectionId: collection.id, filters: request.body.filters ?? [],
      sort: request.body.sort, limit: 500});
    return {items: documents.filter((document) => matchesSearch(document, request.body.search ?? "")).map(documentDto)};
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

  app.delete("/v1/data/collections/:collectionName/documents", {
    schema: {params: CollectionParams, response: {200: DeletedCount, 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    return {deleted: await store.deleteDocuments({teamId, collectionId: collection.id})};
  });

  // POST statt DELETE mit Body: Der App-Client sendet bei DELETE keinen Body.
  app.post("/v1/data/collections/:collectionName/documents/delete", {
    schema: {params: CollectionParams,
      body: Type.Object({ids: Type.Array(Type.String({minLength: 1, maxLength: 200}), {maxItems: maximumDocumentIdsPerDelete})}),
      response: {200: DeletedCount, 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await collectionFor(teamId, request.params.collectionName);
    if (collection === null) return reply.code(404).send(collectionMissing);
    return {deleted: await store.deleteDocuments({teamId, collectionId: collection.id, documentIds: request.body.ids})};
  });
};
