import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyError} from "fastify";
import {type DocumentCollection} from "../../domain/entities/document-collection.js";
import {type DocumentData} from "../../domain/entities/document.js";
import {type DocumentFilter, type DocumentSort} from "../../domain/entities/document-filter.js";
import {type DocumentStore} from "../../domain/repositories/document-store.js";
import {
  documentTableFormats, exportDocuments, maximumImportBytes, parseDocumentImport,
} from "../../domain/services/document-table-codec.js";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {
  CollectionParams, collectionMissing, type DataRoutesOptions, DocumentFilters, DocumentSortSchema, matchesSearch,
} from "./local-data-route-schemas.js";

const exportPageSize = 500;
const previewSampleSize = 5;
const contentTypes = {csv: "text/csv; charset=utf-8", json: "application/json; charset=utf-8"} as const;

const ImportPreview = Type.Object({
  count: Type.Integer(), fields: Type.Array(Type.String()),
  renamedFields: Type.Array(Type.Object({from: Type.String(), to: Type.String()})),
  sample: Type.Array(Type.Record(Type.String(), Type.Unknown())), issues: Type.Array(Type.String()),
});

/** Sammlungen als CSV/JSON herunterladen und Dateien mit Vorschau importieren. */
export const dataTransferRoutes: FastifyPluginAsyncTypebox<DataRoutesOptions> = async (app, {store}) => {
  app.addContentTypeParser("application/octet-stream", {parseAs: "buffer", bodyLimit: maximumImportBytes},
    (_request, body, done) => done(null, body));
  // Der globale Handler meldet Parserfehler als 400; eine zu große Datei verdient eine eigene Antwort.
  app.setErrorHandler((error: FastifyError, _request, reply) => {
    if (error.code === "FST_ERR_CTP_BODY_TOO_LARGE") return reply.code(413).send({error: "Die Datei ist größer als 5 MB."});
    throw error;
  });

  app.post("/v1/data/collections/:collectionName/export", {
    // Ohne Antwort-Schema: Die Datei geht als Text hinaus, nicht als JSON-Zeichenkette.
    schema: {params: CollectionParams,
      body: Type.Object({format: Type.Enum(documentTableFormats), search: Type.Optional(Type.String()),
        filters: DocumentFilters, sort: DocumentSortSchema})},
  }, async (request, reply) => {
    const collection = await store.findCollectionByName({teamId: request.workspace.teamId, displayName: request.params.collectionName});
    if (collection === null) return reply.code(404).send(collectionMissing);
    const {format, search, filters, sort} = request.body;
    const documents = await allDocuments(store, collection, filters ?? [], sort, search ?? "");
    return reply.header("content-type", contentTypes[format])
      .header("content-disposition", attachment(`${collection.displayName}.${format}`))
      .send(exportDocuments(format, documents));
  });

  app.post("/v1/data/collections/:collectionName/import", {
    bodyLimit: maximumImportBytes,
    schema: {params: CollectionParams,
      querystring: Type.Object({format: Type.Enum(documentTableFormats), dryRun: Type.Optional(Type.Boolean())}),
      response: {200: Type.Union([ImportPreview, Type.Object({imported: Type.Integer()})]),
        404: ErrorResponse, 415: ErrorResponse, 422: ImportPreview}},
  }, async (request, reply) => {
    if (!Buffer.isBuffer(request.body)) return reply.code(415).send({error: "Der Import erwartet die Datei als application/octet-stream."});
    const {teamId} = request.workspace;
    const collection = await store.findCollectionByName({teamId, displayName: request.params.collectionName});
    if (collection === null) return reply.code(404).send(collectionMissing);
    const parsed = parseDocumentImport(request.query.format, request.body.toString("utf8"));
    const preview = {count: parsed.items.length, fields: parsed.fields, renamedFields: parsed.renamed,
      sample: parsed.items.slice(0, previewSampleSize), issues: parsed.issues};
    if (request.query.dryRun ?? true) return preview;
    if (parsed.issues.length > 0) return reply.code(422).send(preview);
    return {imported: await store.createMany({teamId, collectionId: collection.id, items: parsed.items})};
  });
};

/** Alle Treffer seitenweise — der Export kennt keine Obergrenze wie die Ansicht. */
async function allDocuments(
  store: DocumentStore, collection: DocumentCollection, filters: readonly DocumentFilter[],
  sort: DocumentSort | undefined, search: string,
): Promise<DocumentData[]> {
  const result: DocumentData[] = [];
  for (let offset = 0; ; offset += exportPageSize) {
    const page = await store.findMany({teamId: collection.teamId, collectionId: collection.id, filters, sort,
      limit: exportPageSize, offset});
    result.push(...page.filter((document) => matchesSearch(document, search)).map((document) => document.data));
    if (page.length < exportPageSize) return result;
  }
}

/** ASCII-Fallback plus RFC 5987 für Umlaute im Dateinamen. */
function attachment(fileName: string): string {
  const fallback = fileName.replace(/[^\x20-\x7E]/g, "_").replace(/["\\]/g, "_");
  return `attachment; filename="${fallback}"; filename*=UTF-8''${encodeURIComponent(fileName)}`;
}
