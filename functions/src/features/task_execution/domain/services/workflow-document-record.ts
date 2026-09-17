import {
  type DocumentData,
  type DocumentRecord,
} from "../../../data/domain/entities/document.js";

export type WorkflowDocumentRecord = {
  fields: DocumentData;
};

export function workflowDocumentRecordFor(
  document: DocumentRecord,
): WorkflowDocumentRecord {
  return {
    fields: document.data,
  };
}
