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
