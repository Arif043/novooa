import {createHash} from "node:crypto";

/**
 * Die Umgebung einer normalisierten Paketliste (`normalizedScriptPackages`):
 * SHA-256 über die Zeilen. Gleiche Liste, gleiche Umgebung — Paketdienst und
 * Script-Container kennen die Umgebung nur unter dieser ID.
 */
export function scriptPackageEnvironmentId(normalizedPackages: readonly string[]): string {
  return createHash("sha256").update(normalizedPackages.join("\n")).digest("hex");
}
