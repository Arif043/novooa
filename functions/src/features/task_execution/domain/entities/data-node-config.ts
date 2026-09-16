import {type DocumentFilterOperator} from
  "../../../data/domain/entities/document-filter.js";

export type DocumentLookupFilterConfig = {
  field: string;
  operator: DocumentFilterOperator;
  value: string;
};

export type DocumentLookupNodeConfig = {
  primitive: "documentLookup";
  collectionId: string;
  filters: DocumentLookupFilterConfig[];
};

export const documentSaveModes = ["create", "update", "upsert"] as const;

export type DocumentSaveMode = (typeof documentSaveModes)[number];

export type DocumentFieldAssignment = {
  field: string;
  value: string;
};

export type SaveDocumentNodeConfig = {
  primitive: "saveDocument";
  collectionId: string;
  mode: DocumentSaveMode;
  documentId: string;
  fields: DocumentFieldAssignment[];
};
