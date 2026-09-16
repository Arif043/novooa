import {
  type DocumentData,
  type DocumentRecord,
} from "../../../data/domain/entities/document.js";

export type WorkflowDocumentRecord = {
  id: string;
  fields: DocumentData;
  version: number;
  createdAt: string;
  updatedAt: string;
};

export function workflowDocumentRecordFor(
  document: DocumentRecord,
): WorkflowDocumentRecord {
  return {
    id: document.id,
    fields: document.data,
    version: document.version,
    createdAt: document.createdAt.toISOString(),
    updatedAt: document.updatedAt.toISOString(),
  };
}
