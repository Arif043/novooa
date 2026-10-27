import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {randomUUID} from "node:crypto";
import {DocumentCollectionNameTakenError} from "../../domain/entities/document-collection.js";
import {ErrorResponse, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {
  CollectionBody, CollectionDto, CollectionParams, collectionDto, collectionMissing, collectionNameTaken,
  type DataRoutesOptions,
} from "./local-data-route-schemas.js";

/** Sammlungen auflisten, anlegen, umbenennen und samt Datensätzen löschen. */
export const dataCollectionRoutes: FastifyPluginAsyncTypebox<DataRoutesOptions> = async (app, {store}) => {
  app.get("/v1/data/collections", {schema: {response: {200: ItemsOf(CollectionDto)}}}, async (request) => {
    const collections = await store.listCollections(request.workspace.teamId);
    return {items: await Promise.all(collections.map((collection) => collectionDto(store, collection)))};
  });

  app.post("/v1/data/collections", {
    schema: {body: CollectionBody, response: {201: CollectionDto, 400: ErrorResponse, 409: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const displayName = request.body.name.trim();
    if (displayName.length === 0) return reply.code(400).send({error: "Der Name der Datensammlung fehlt."});
    if (await store.findCollectionByName({teamId, displayName}) !== null) return reply.code(409).send(collectionNameTaken);
    const created = await store.createCollection({teamId, id: randomUUID(), displayName});
    return reply.code(201).send(await collectionDto(store, created));
  });

  app.put("/v1/data/collections/:collectionName", {
    schema: {params: CollectionParams, body: CollectionBody,
      response: {200: CollectionDto, 400: ErrorResponse, 404: ErrorResponse, 409: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const displayName = request.body.name.trim();
    if (displayName.length === 0) return reply.code(400).send({error: "Der Name der Datensammlung fehlt."});
    const collection = await store.findCollectionByName({teamId, displayName: request.params.collectionName});
    if (collection === null) return reply.code(404).send(collectionMissing);
    try {
      const renamed = await store.renameCollection({teamId, collectionId: collection.id, displayName});
      return renamed === null ? reply.code(404).send(collectionMissing) : collectionDto(store, renamed);
    } catch (error) {
      if (error instanceof DocumentCollectionNameTakenError) return reply.code(409).send(collectionNameTaken);
      throw error;
    }
  });

  app.delete("/v1/data/collections/:collectionName", {
    schema: {params: CollectionParams, response: {204: Type.Null(), 404: ErrorResponse}},
  }, async (request, reply) => {
    const {teamId} = request.workspace;
    const collection = await store.findCollectionByName({teamId, displayName: request.params.collectionName});
    if (collection === null) return reply.code(404).send(collectionMissing);
    await store.deleteCollection({teamId, collectionId: collection.id});
    return reply.code(204).send(null);
  });
};
