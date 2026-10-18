import {err, ok, Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {documentFilterValueFor} from "../services/document-filter-values.js";
import {
  type DocumentData,
  type DocumentRecord,
  validateDocumentData,
} from "../../../data/domain/entities/document.js";
import {
  type DocumentFilter,
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
    if (node.config.primitive !== "saveDocument") return err(nodeFailures.configurationMissing(node.primitive));
    const config = node.config;
    const inputsOrFailure = dataFor(config, runContext)
      .andThen((data) => filtersFor(config, runContext).map((filters) => ({data, filters})));
    if (inputsOrFailure.isErr()) return err(inputsOrFailure.error);
    const {data, filters} = inputsOrFailure.value;
    const collection = await runContext.documentStore.ensureCollection({
      teamId: runContext.teamId, displayName: config.collectionName.trim(),
    });
    const saved = filters.length === 0
      ? await createDocument(collection.id, data, runContext)
      : await saveMatchingDocuments(collection.id, filters, data, runContext);
    return ok(executedNode(node, outputsFor(saved)));
  },
};

type SaveConfig = Extract<Parameters<NodeExecutor["execute"]>[0]["config"], {primitive: "saveDocument"}>;

function dataFor(
  config: SaveConfig,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Result<DocumentData, NodeFailure> {
  const names = config.fields.map((field) => field.field.trim());
  if (names.length === 0 || new Set(names).size !== names.length) {
    return err(nodeFailures.settingInvalid("documentFieldDuplicate"));
  }
  const values = config.fields.map((field) => runContext.templateExpressionResolver.resolveValue(field.value));
  const missing = values.findIndex((value) => value === undefined);
  if (missing >= 0) return err(nodeFailures.settingInvalid("documentFieldValue", names[missing]));
  const data = Object.fromEntries(names.map((name, index) => [name, values[index]])) as DocumentData;
  validateDocumentData(data);
  return ok(data);
}

function filtersFor(
  config: SaveConfig,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Result<DocumentFilter[], NodeFailure> {
  return Result.combine(config.filters.map((filter) => {
    const resolved = runContext.templateExpressionResolver.resolveValue(filter.value);
    return documentFilterValueFor(filter.operator, resolved).map((value) => {
      const documentFilter: DocumentFilter = {field: filter.field.trim(), operator: filter.operator, value};
      validateDocumentFilter(documentFilter);
      return documentFilter;
    });
  }));
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
