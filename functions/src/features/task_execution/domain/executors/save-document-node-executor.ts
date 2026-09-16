import {
  type DocumentData,
  type DocumentRecord,
  type DocumentValue,
  validateDocumentData,
} from "../../../data/domain/entities/document.js";
import {
  type NodeExecutor,
  executedNode,
  stringOutput,
} from "./node-executor.js";
import {workflowDocumentRecordFor} from "../services/workflow-document-record.js";

export const saveDocumentNodeExecutor: NodeExecutor = {
  primitive: "saveDocument",
  async execute(input, runContext) {
    const config = configFor(input.node);
    const saved = await saveDocument(config, runContext);
    return executedNode(input.node, outputsFor(saved));
  },
};

function configFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]) {
  if (node.config.primitive !== "saveDocument") {
    throw new Error("Datensatz speichern: Die Konfiguration fehlt.");
  }
  return node.config;
}

async function saveDocument(
  config: ReturnType<typeof configFor>,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocument> {
  const data = dataFor(config, runContext);
  if (config.mode === "create") return createDocument(config, data, runContext);
  const documentId = documentIdFor(config, runContext);
  if (config.mode === "update") return updateDocument(config, documentId, data, runContext);
  return upsertDocument(config, documentId, data, runContext);
}

async function createDocument(
  config: ReturnType<typeof configFor>,
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocument> {
  const record = await runContext.documentStore.create({
    teamId: runContext.teamId, collectionId: collectionIdFor(config),
    documentId: optionalDocumentIdFor(config, runContext), data,
  });
  return {created: true, record};
}

async function updateDocument(
  config: ReturnType<typeof configFor>,
  documentId: string,
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocument> {
  const current = await requiredDocumentFor(config, documentId, runContext);
  const record = await runContext.documentStore.update({
    teamId: runContext.teamId, collectionId: collectionIdFor(config), documentId,
    data: {...current.data, ...data}, expectedVersion: current.version,
  });
  return {created: false, record};
}

async function upsertDocument(
  config: ReturnType<typeof configFor>,
  documentId: string,
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocument> {
  const current = await runContext.documentStore.findById({
    teamId: runContext.teamId, collectionId: collectionIdFor(config), documentId,
  });
  const record = await runContext.documentStore.upsert({
    teamId: runContext.teamId, collectionId: collectionIdFor(config), documentId,
    data: {...current?.data, ...data}, expectedVersion: current?.version,
  });
  return {created: current === null, record};
}

async function requiredDocumentFor(
  config: ReturnType<typeof configFor>,
  documentId: string,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<DocumentRecord> {
  const record = await runContext.documentStore.findById({
    teamId: runContext.teamId, collectionId: collectionIdFor(config), documentId,
  });
  if (record !== null) return record;
  throw new Error("Datensatz speichern: Der Datensatz wurde nicht gefunden.");
}

function dataFor(
  config: ReturnType<typeof configFor>,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): DocumentData {
  const data = Object.fromEntries(config.fields.map((field) => [
    field.field.trim(), valueFor(field.value, runContext),
  ])) as DocumentData;
  requireUniqueFields(config);
  validateDocumentData(data);
  return data;
}

function valueFor(
  template: string,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): DocumentValue {
  const value = runContext.resolveTemplateValue(template);
  if (value !== undefined) return value as DocumentValue;
  throw new Error("Datensatz speichern: Ein Feldwert konnte nicht aufgelöst werden.");
}

function requireUniqueFields(config: ReturnType<typeof configFor>): void {
  const fields = config.fields.map((field) => field.field.trim());
  if (fields.length === 0 || new Set(fields).size !== fields.length) {
    throw new Error("Datensatz speichern: Jedes Feld muss genau einmal gesetzt sein.");
  }
}

function collectionIdFor(config: ReturnType<typeof configFor>): string {
  return config.collectionId.trim();
}

function documentIdFor(
  config: ReturnType<typeof configFor>,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): string {
  const documentId = optionalDocumentIdFor(config, runContext);
  if (documentId) return documentId;
  throw new Error("Datensatz speichern: Für diese Speicherart wird eine Datensatz-ID benötigt.");
}

function optionalDocumentIdFor(
  config: ReturnType<typeof configFor>,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): string | undefined {
  const value = runContext.resolveTemplateValue(config.documentId);
  return typeof value === "string" && value.trim().length > 0 ? value.trim() : undefined;
}

function outputsFor(saved: SavedDocument) {
  return {
    value: stringOutput("Datensatz gespeichert"),
    recordId: stringOutput(saved.record.id),
    record: {type: "json" as const, value: workflowDocumentRecordFor(saved.record)},
    isNew: {type: "boolean" as const, value: saved.created},
  };
}

type SavedDocument = {created: boolean; record: DocumentRecord};
