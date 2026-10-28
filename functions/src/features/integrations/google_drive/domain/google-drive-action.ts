import {type NodeOutputValue} from "../../../task_execution/domain/entities/task.js";
import {type TeamFileContentReader} from "../../../files/domain/repositories/team-file-content-reader.js";
import {type TeamFileStore} from "../../../files/domain/repositories/team-file-store.js";
import {type GoogleDriveFiles} from "./google-drive-file.js";

export type GoogleDriveActionContext = {
  drive: GoogleDriveFiles;
  teamId: string;
  /** Die Eingaben des Bausteins, noch nicht geprüft und mit unaufgelösten Templates. */
  params: Record<string, unknown>;
  resolveText: (template: string) => string;
  /** Wie `resolveText`, behält aber Dateien, Tabellen und Objekte als Wert. */
  resolveValue: (template: string) => unknown;
  files: {reader: TeamFileContentReader; store: TeamFileStore};
};

/** Eine Aktion des Drive-Bausteins (z. B. „In Google Drive speichern“). Sie prüft ihre `params` selbst. */
export type GoogleDriveAction = {
  id: string;
  execute(context: GoogleDriveActionContext): Promise<Record<string, NodeOutputValue>>;
  /** Nur Aktionen, die in Google Drive etwas anlegen: ein Kennzeichen der Folge, z. B. der Dateiname. */
  effectLabel?(outputs: Record<string, NodeOutputValue>): string | undefined;
};

export class GoogleDriveActionRegistry {
  private readonly actions = new Map<string, GoogleDriveAction>();

  register(action: GoogleDriveAction): this {
    this.actions.set(action.id, action);
    return this;
  }

  find(id: string): GoogleDriveAction | undefined {
    return this.actions.get(id);
  }
}

/** Liest einen Text-Parameter; fehlt er, gilt der Leerstring. */
export function textParam(params: Record<string, unknown>, name: string): string {
  const value = params[name];
  return typeof value === "string" ? value : "";
}
