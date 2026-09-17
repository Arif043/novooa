import {type DocumentFilterOperator} from
  "../../../data/domain/entities/document-filter.js";

export type DocumentLookupFilterConfig = {
  field: string;
  operator: DocumentFilterOperator;
  value: string;
};

export type DocumentLookupNodeConfig = {
  primitive: "documentLookup";
  collectionName: string;
  filters: DocumentLookupFilterConfig[];
};

export type DocumentFieldAssignment = {
  field: string;
  value: string;
};

export type SaveDocumentNodeConfig = {
  primitive: "saveDocument";
  collectionName: string;
  filters: DocumentLookupFilterConfig[];
  fields: DocumentFieldAssignment[];
};
