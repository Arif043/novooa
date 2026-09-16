import {
  type DocumentRecord,
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
import {workflowDocumentRecordFor} from "../services/workflow-document-record.js";

const foundMessage = "Datensatz gefunden";
const notFoundMessage = "Kein passender Datensatz gefunden";
const failureMessage = "Suche fehlgeschlagen";

export const documentLookupNodeExecutor: NodeExecutor = {
  primitive: "documentLookup",
  async execute(input, runContext) {
    try {
      const document = await runContext.documentStore.findOne(inputFor(input.node, runContext));
      return executedNode(input.node, outputsFor(document));
    } catch {
      return executedNode(input.node, failureOutputs());
    }
  },
};

function inputFor(
  node: Parameters<NodeExecutor["execute"]>[0]["node"],
  runContext: Parameters<NodeExecutor["execute"]>[1],
) {
  const config = configFor(node);
  return {
    teamId: runContext.teamId,
    collectionId: config.collectionId.trim(),
    filters: config.filters.map((filter) => filterFor(filter, runContext)),
  };
}

function configFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]) {
  if (node.config.primitive !== "documentLookup") {
    throw new Error("Datensatz suchen: Die Konfiguration fehlt.");
  }
  return node.config;
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
  const resolved = runContext.resolveTemplateValue(filter.value);
  if (isNumericOperator(filter.operator)) return numberValueFor(resolved);
  if (isDocumentFilterValue(resolved)) return resolved;
  throw new Error("Datensatz suchen: Der Filterwert ist ungültig.");
}

function numberValueFor(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string" && value.trim().length > 0) {
    const number = Number(value);
    if (Number.isFinite(number)) return number;
  }
  throw new Error("Datensatz suchen: Für den Vergleich wird eine Zahl benötigt.");
}

function isDocumentFilterValue(value: unknown): value is DocumentFilterValue {
  return typeof value === "string" || typeof value === "boolean" ||
    (typeof value === "number" && Number.isFinite(value));
}

function outputsFor(document: DocumentRecord | null) {
  if (document === null) return absentOutputs();
  return {
    value: stringOutput(foundMessage),
    found: {type: "boolean" as const, value: true},
    recordId: stringOutput(document.id),
    record: {type: "json" as const, value: workflowDocumentRecordFor(document)},
    message: stringOutput(foundMessage),
  };
}

function absentOutputs() {
  return {
    value: stringOutput(notFoundMessage),
    found: {type: "boolean" as const, value: false},
    recordId: stringOutput(""),
    record: {type: "json" as const, value: null},
    message: stringOutput(notFoundMessage),
  };
}

function failureOutputs() {
  return {
    value: stringOutput(failureMessage),
    found: {type: "boolean" as const, value: false},
    recordId: stringOutput(""),
    record: {type: "json" as const, value: null},
    message: stringOutput("Der Datensatz konnte nicht gesucht werden."),
  };
}
