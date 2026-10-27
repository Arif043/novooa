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

/** Eine Sammlung über ihre interne Identität innerhalb eines Teams. */
export type DocumentCollectionRef = {
  teamId: string;
  collectionId: string;
};

export type RenameDocumentCollectionInput = DocumentCollectionRef & {displayName: string};

/** Der gewünschte Name gehört schon einer anderen Sammlung des Teams. */
export class DocumentCollectionNameTakenError extends Error {
  constructor() {
    super("Eine Datensammlung mit diesem Namen existiert bereits.");
    this.name = "DocumentCollectionNameTakenError";
  }
}

export function validateDocumentCollectionRef(input: DocumentCollectionRef): void {
  validateTeamId(input.teamId);
  validateDocumentCollectionId(input.collectionId);
}

export function validateRenameDocumentCollectionInput(input: RenameDocumentCollectionInput): void {
  validateDocumentCollectionRef(input);
  validateDocumentCollectionNameInput(input);
}

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
