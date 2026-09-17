export type DocumentCollection = {
  id: string;
  teamId: string;
  displayName: string;
  createdAt: Date;
  updatedAt: Date;
};

export type CreateDocumentCollectionInput = {
  id: string;
  teamId: string;
  displayName: string;
};

export type DocumentCollectionNameInput = {
  teamId: string;
  displayName: string;
};

export function validateDocumentCollectionInput(
  input: CreateDocumentCollectionInput,
): void {
  validateDocumentCollectionId(input.id);
  validateDocumentCollectionNameInput(input);
}

export function validateDocumentCollectionNameInput(
  input: DocumentCollectionNameInput,
): void {
  validateTeamId(input.teamId);
  if (input.displayName.trim().length === 0 || input.displayName.length > 120) {
    throw new Error("Der Name der Datensammlung ist ungültig.");
  }
}

export function validateDocumentCollectionId(collectionId: string): void {
  if (collectionId.trim().length === 0 || collectionId.length > 200) {
    throw new Error("Die interne Sammlungs-ID ist ungültig.");
  }
}

export function validateTeamId(teamId: string): void {
  if (teamId.trim().length === 0 || teamId.length > 200) {
    throw new Error("Die Team-ID ist ungültig.");
  }
}
