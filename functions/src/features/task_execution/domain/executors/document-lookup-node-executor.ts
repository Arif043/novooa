import {err, ok, Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {nodeFailures} from "../entities/node-failures.js";
import {
  type DocumentRecord,
} from "../../../data/domain/entities/document.js";
import {
  type DocumentFilter,
  validateDocumentFilter,
} from "../../../data/domain/entities/document-filter.js";
import {documentFilterValueFor} from "../services/document-filter-values.js";
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
  async execute(node, runContext) {
    if (node.config.primitive !== "documentLookup") return err(nodeFailures.configurationMissing(node.primitive));
    const config = node.config;
    // Eine gescheiterte Suche ist hier ein Ergebnis („nicht gefunden, weil …“), kein Abbruch des Laufs.
    try {
      const documentOrFailure = await findDocument(config, runContext);
      return ok(executedNode(node, documentOrFailure.isOk() ? outputsFor(documentOrFailure.value) : failureOutputs()));
    } catch {
      return ok(executedNode(node, failureOutputs()));
    }
  },
};

type LookupConfig = Extract<Parameters<NodeExecutor["execute"]>[0]["config"], {primitive: "documentLookup"}>;

async function findDocument(
  config: LookupConfig,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<Result<DocumentRecord | null, NodeFailure>> {
  const filtersOrFailure = Result.combine(config.filters.map((filter) => filterFor(filter, runContext)));
  if (filtersOrFailure.isErr()) return err(filtersOrFailure.error);
  const collection = await runContext.documentStore.findCollectionByName({
    teamId: runContext.teamId, displayName: config.collectionName.trim(),
  });
  if (collection === null) return ok(null);
  return ok(await runContext.documentStore.findOne({
    teamId: runContext.teamId, collectionId: collection.id, filters: filtersOrFailure.value,
  }));
}

function filterFor(
  filter: LookupConfig["filters"][number],
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Result<DocumentFilter, NodeFailure> {
  const resolved = runContext.templateExpressionResolver.resolveValue(filter.value);
  return documentFilterValueFor(filter.operator, resolved).map((value) => {
    const documentFilter: DocumentFilter = {field: filter.field.trim(), operator: filter.operator, value};
    validateDocumentFilter(documentFilter);
    return documentFilter;
  });
}


function outputsFor(document: DocumentRecord | null) {
  if (document === null) return absentOutputs();
  return {
    value: stringOutput(foundMessage),
    found: {type: "boolean" as const, value: true},
    record: {type: "json" as const, value: workflowDocumentRecordFor(document)},
    message: stringOutput(foundMessage),
  };
}

function absentOutputs() {
  return {
    value: stringOutput(notFoundMessage),
    found: {type: "boolean" as const, value: false},
    record: {type: "json" as const, value: null},
    message: stringOutput(notFoundMessage),
  };
}

function failureOutputs() {
  return {
    value: stringOutput(failureMessage),
    found: {type: "boolean" as const, value: false},
    record: {type: "json" as const, value: null},
    message: stringOutput("Der Datensatz konnte nicht gesucht werden."),
  };
}
