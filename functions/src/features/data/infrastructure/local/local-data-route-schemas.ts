import {Type} from "@fastify/type-provider-typebox";
import {type DocumentCollection} from "../../domain/entities/document-collection.js";
import {type DocumentRecord, type DocumentValue} from "../../domain/entities/document.js";
import {documentFilterOperators, documentSortDirections} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";

export type DataRoutesOptions = {store: DocumentStore};

export const DocumentDto = Type.Object({id: Type.String(), data: JsonObject, createdAt: Type.String(), updatedAt: Type.String()});
export const CollectionDto = Type.Object({
  name: Type.String(), documentCount: Type.Integer(), createdAt: Type.String(), updatedAt: Type.String(),
  /** Felder der jüngsten Datensätze, alphabetisch — Vorschau in der Übersicht. */
  fields: Type.Array(Type.String()),
  /** Letzte Änderung an der Sammlung oder einem ihrer Datensätze. */
  changedAt: Type.String(),
});

/** So viele jüngste Datensätze bestimmen Feldvorschau und letzte Änderung einer Sammlung. */
const collectionPreviewSize = 50;
export const CollectionName = NonEmptyString({maxLength: 120});
export const CollectionBody = Type.Object({name: CollectionName});
export const DocumentFilters = Type.Optional(Type.Array(Type.Object({
  field: Type.String(),
  operator: Type.Enum(documentFilterOperators),
  value: Type.Union([Type.String(), Type.Number(), Type.Boolean()]),
})));
export const DocumentSortSchema = Type.Optional(Type.Object({
  field: Type.String(), direction: Type.Enum(documentSortDirections),
}));
export const DocumentQuery = Type.Object({search: Type.Optional(Type.String()), filters: DocumentFilters, sort: DocumentSortSchema});
export const DocumentBody = Type.Object({data: JsonObject});
export const CollectionParams = Type.Object({collectionName: NonEmptyString({maxLength: 200})});
export const DocumentParams = Type.Object({collectionName: NonEmptyString({maxLength: 200}), documentId: NonEmptyString({maxLength: 200})});
export const DeletedCount = Type.Object({deleted: Type.Integer()});

export const collectionMissing = {error: "Die Datensammlung wurde nicht gefunden."};
export const collectionNameTaken = {error: "Eine Datensammlung mit diesem Namen existiert bereits."};

export async function collectionDto(store: DocumentStore, collection: DocumentCollection) {
  const scope = {teamId: collection.teamId, collectionId: collection.id};
  const recent = await store.findMany({...scope, limit: collectionPreviewSize});
  const newest = Math.max(collection.updatedAt.getTime(), recent[0]?.updatedAt.getTime() ?? 0);
  return {
    name: collection.displayName,
    documentCount: await store.countDocuments(scope),
    createdAt: collection.createdAt.toISOString(), updatedAt: collection.updatedAt.toISOString(),
    fields: [...new Set(recent.flatMap((document) => Object.keys(document.data)))].sort(),
    changedAt: new Date(newest).toISOString(),
  };
}

export function documentDto(document: DocumentRecord) {
  return {id: document.id, data: document.data, createdAt: document.createdAt.toISOString(), updatedAt: document.updatedAt.toISOString()};
}

/** Volltextsuche über alle skalaren Werte; ergänzt die strukturierten Filter der Datenbank. */
export function matchesSearch(document: DocumentRecord, search: string): boolean {
  const needle = search.trim().toLocaleLowerCase();
  return needle.length === 0 || scalarTexts(document.data).some((value) => value.toLocaleLowerCase().includes(needle));
}

function scalarTexts(value: DocumentValue): string[] {
  if (value === null) return ["null"];
  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") return [String(value)];
  if (Array.isArray(value)) return value.flatMap(scalarTexts);
  return Object.values(value).flatMap(scalarTexts);
}
