export function languageModelSecretContext(secretRef: string): readonly string[] {
  return ["language-model-secrets", secretRef, "api-key"];
}

export function licenseSecretContext(payload: Record<string, unknown>): readonly string[] {
  const identifiers = [payload.workspaceId, payload.licenseId, payload.activationId];
  if (identifiers.some((id) => typeof id !== "string" || !id.length)) {
    throw new Error("Ungültiger Lizenz-Feldkontext.");
  }
  return ["runtime-license", ...identifiers as string[], "activation-secret"];
}

export function mlServiceTokenContext(tenantId: string): readonly string[] {
  if (!tenantId.length) throw new Error("Ungültiger Feldkontext für den ML-Dienst.");
  return ["ml-service", tenantId, "token"];
}

/** Bindet den verschlüsselten Passwort-Hash an genau ein Konto. */
export function passwordHashContext(uid: string): readonly string[] {
  if (!uid.length) throw new Error("Ungültiger Feldkontext für ein Passwort.");
  return ["runtime-password", uid, "scrypt-hash"];
}
