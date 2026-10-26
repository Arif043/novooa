import {SystemModelVersionConflictError} from "../../domain/usecases/publish-system-model.js";

/** Fehlermeldung für die Konsole; bei einem Versionskonflikt mit dem Weg, ihn bewusst aufzulösen. */
export function cliErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof SystemModelVersionConflictError) {
    return `${error.message} Zum Ersetzen erneut mit --replace-version aufrufen.`;
  }
  return error instanceof Error ? error.message : fallback;
}
