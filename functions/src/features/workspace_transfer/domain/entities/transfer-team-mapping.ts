import {InvalidTransferArchiveError} from "./transfer-errors.js";

/**
 * Dateien liegen unter `teams/{teamId}/files/...`. Ein Export kann in einen
 * anderen Arbeitsbereich importiert werden, daher werden diese Pfade und
 * Verweise darauf (z. B. Datei-Anhänge in Aufgaben) auf das Zielteam umgeschrieben.
 */
export class TransferTeamMapping {
  constructor(
    readonly sourceTeamId: string,
    readonly targetTeamId: string,
  ) {}

  storagePath(sourcePath: string): string {
    const prefix = filesPrefix(this.sourceTeamId);
    if (!sourcePath.startsWith(prefix) || !isSafeRelativePath(sourcePath)) {
      throw new InvalidTransferArchiveError("Der Export enthält einen ungültigen Dateipfad.");
    }
    return filesPrefix(this.targetTeamId) + sourcePath.slice(prefix.length);
  }

  references(text: string): string {
    if (this.sourceTeamId === this.targetTeamId) return text;
    return text.split(filesPrefix(this.sourceTeamId)).join(filesPrefix(this.targetTeamId));
  }
}

export function isTeamStoragePath(teamId: string, storagePath: string): boolean {
  return storagePath.startsWith(filesPrefix(teamId)) && isSafeRelativePath(storagePath);
}

function filesPrefix(teamId: string): string {
  return `teams/${teamId}/files/`;
}

function isSafeRelativePath(value: string): boolean {
  return value.split("/").every((segment) => segment.length > 0 && segment !== "." && segment !== "..") &&
    !value.includes("\\") && !value.includes("\0");
}
