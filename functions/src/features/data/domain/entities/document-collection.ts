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

export function validateDocumentCollectionInput(
  input: CreateDocumentCollectionInput,
): void {
  validateIdentifier(input.id, "Die Sammlungs-ID");
  validateTeamId(input.teamId);
  if (input.displayName.trim().length === 0 || input.displayName.length > 120) {
    throw new Error("Der Name der Datensammlung ist ungültig.");
  }
}

export function validateDocumentCollectionId(collectionId: string): void {
  validateIdentifier(collectionId, "Die Sammlungs-ID");
}

export function validateTeamId(teamId: string): void {
  if (teamId.trim().length === 0 || teamId.length > 200) {
    throw new Error("Die Team-ID ist ungültig.");
  }
}

function validateIdentifier(value: string, label: string): void {
  if (!/^[a-z][a-z0-9_]{0,63}$/.test(value)) {
    throw new Error(`${label} darf nur Kleinbuchstaben, Zahlen und Unterstriche enthalten.`);
  }
}
