import {
  type DocumentData,
  type DocumentRecord,
  type DocumentValue,
  validateDocumentData,
} from "../../../data/domain/entities/document.js";
import {
  type DocumentFilter,
  type DocumentFilterValue,
  isNumericOperator,
  validateDocumentFilter,
} from "../../../data/domain/entities/document-filter.js";
import {
  type NodeExecutor,
  executedNode,
  stringOutput,
} from "./node-executor.js";

export const saveDocumentNodeExecutor: NodeExecutor = {
  primitive: "saveDocument",
  async execute(node, runContext) {
    const config = configFor(node);
    const collection = await runContext.documentStore.ensureCollection({
      teamId: runContext.teamId, displayName: config.collectionName.trim(),
    });
    const data = dataFor(config, runContext);
    const filters = filtersFor(config, runContext);
    const saved = filters.length === 0
      ? await createDocument(collection.id, data, runContext)
      : await saveMatchingDocuments(collection.id, filters, data, runContext);
    return executedNode(node, outputsFor(saved));
  },
};

function configFor(node: Parameters<NodeExecutor["execute"]>[0]) {
  if (node.config.primitive !== "saveDocument") {
    throw new Error("Datensatz speichern: Die Konfiguration fehlt.");
  }
  return node.config;
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

function filtersFor(
  config: ReturnType<typeof configFor>,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): DocumentFilter[] {
  return config.filters.map((filter) => filterFor(filter, runContext));
}

function filterFor(
  filter: ReturnType<typeof configFor>["filters"][number],
  runContext: Parameters<NodeExecutor["execute"]>[1],
): DocumentFilter {
  const resolved: DocumentFilter = {
    field: filter.field.trim(),
    operator: filter.operator,
    value: filterValueFor(filter, runContext),
  };
  validateDocumentFilter(resolved);
  return resolved;
}

function filterValueFor(
  filter: ReturnType<typeof configFor>["filters"][number],
  runContext: Parameters<NodeExecutor["execute"]>[1],
): DocumentFilterValue {
  const value = runContext.resolveTemplateValue(filter.value);
  if (isNumericOperator(filter.operator)) return numberValueFor(value);
  if (isDocumentFilterValue(value)) return value;
  throw new Error("Datensatz speichern: Der Filterwert ist ungültig.");
}

function numberValueFor(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim().length > 0) {
    const number = Number(value);
    if (Number.isFinite(number)) return number;
  }
  throw new Error("Datensatz speichern: Für den Vergleich wird eine Zahl benötigt.");
}

function isDocumentFilterValue(value: unknown): value is DocumentFilterValue {
  return typeof value === "string" || typeof value === "boolean" ||
    (typeof value === "number" && Number.isFinite(value));
}

async function saveMatchingDocuments(
  collectionId: string,
  filters: readonly DocumentFilter[],
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocuments> {
  const matching = await runContext.documentStore.findMany({
    teamId: runContext.teamId, collectionId, filters: [...filters],
  });
  return saveOrUpdate(collectionId, matching, data, runContext);
}
async function saveOrUpdate(
  collectionId: string,
  matching: readonly DocumentRecord[],
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocuments> {
  if (matching.length === 0) return createDocument(collectionId, data, runContext);
  const records = await Promise.all(matching.map((current) => updateDocument(
    collectionId, current, data, runContext,
  )));
  return {created: false, records};
}

async function createDocument(
  collectionId: string,
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<SavedDocuments> {
  const record = await runContext.documentStore.create({
    teamId: runContext.teamId, collectionId, data,
  });
  return {created: true, records: [record]};
}

function updateDocument(
  collectionId: string,
  current: DocumentRecord,
  data: DocumentData,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<DocumentRecord> {
  return runContext.documentStore.update({
    teamId: runContext.teamId,
    collectionId,
    documentId: current.id,
    data: {...current.data, ...data},
    expectedVersion: current.version,
  });
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

function outputsFor(saved: SavedDocuments) {
  return {
    value: stringOutput("Datensätze gespeichert"),
    created: {type: "boolean" as const, value: saved.created},
    count: {type: "number" as const, value: saved.records.length},
    records: {
      type: "json" as const,
      value: saved.records.map((record) => ({fields: record.data})),
    },
  };
}

type SavedDocuments = {created: boolean; records: DocumentRecord[]};
