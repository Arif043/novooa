import {nodeFailures} from "../entities/node-failures.js";
import {err, ok} from "neverthrow";
import {type DocumentRecord} from "../../../data/domain/entities/document.js";
import {type WorkflowTable} from "../entities/workflow-value.js";
import {
  type NodeExecutor,
  executedNode,
} from "./node-executor.js";
import {tableOutput} from "../entities/workflow-value.js";

const maxRecords = 500;

export const tableFromCollectionNodeExecutor: NodeExecutor = {
  primitive: "tableFromCollection",
  async execute(node, runContext) {
    if (node.config.primitive !== "tableFromCollection") return err(nodeFailures.configurationMissing(node.primitive));
    const config = node.config;
    const collectionName = runContext.templateExpressionResolver
      .resolveText(config.collectionName)
      .trim();
    const records = await recordsFor(collectionName, runContext);
    const table = tableFrom(records);
    return ok(executedNode(node, {
      value: tableOutput(table),
      rowCount: {type: "number", value: table.rows.length},
    }));
  },
};

async function recordsFor(
  collectionName: string,
  runContext: Parameters<NodeExecutor["execute"]>[1],
): Promise<DocumentRecord[]> {
  const collection = await runContext.documentStore.findCollectionByName({
    teamId: runContext.teamId, displayName: collectionName,
  });
  if (collection === null) return [];
  return runContext.documentStore.findMany({
    teamId: runContext.teamId,
    collectionId: collection.id,
    limit: maxRecords,
  });
}

/** Baut Spalten als Vereinigung aller Feldnamen (Erstauftritts-Reihenfolge,
 * da Sammlungen schemalos sind) und richtet jede Zeile darauf aus — fehlende
 * Felder werden zu `null`. */
function tableFrom(records: DocumentRecord[]): WorkflowTable {
  const columns = columnsFrom(records);
  const rows = records.map((record) => columns.map(
    (column) => record.data[column] ?? null,
  ));
  return {columns, rows};
}

function columnsFrom(records: DocumentRecord[]): string[] {
  const columns: string[] = [];
  const seen = new Set<string>();
  for (const record of records) {
    for (const field of Object.keys(record.data)) {
      if (seen.has(field)) continue;
      seen.add(field);
      columns.push(field);
    }
  }
  return columns;
}
