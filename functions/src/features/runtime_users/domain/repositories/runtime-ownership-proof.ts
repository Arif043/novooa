/** Nachweis über den Lizenz-Token, mit dem die Runtime aktiviert wurde (Ersteinrichtung, Notzugang). */
export interface RuntimeOwnershipProof {
  matchesActivationToken(token: unknown): boolean;
}
