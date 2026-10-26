import {UnknownModelTagError} from "../../domain/entities/model-tag-vocabulary.js";
import {SystemModelVersionConflictError} from "../../domain/usecases/publish-system-model.js";

/** Fehlermeldung für die Konsole; bei Versionskonflikt oder unbekanntem Tag mit dem Weg, das aufzulösen. */
export function cliErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof SystemModelVersionConflictError) {
    return `${error.message} Zum Ersetzen erneut mit --replace-version aufrufen.`;
  }
  if (error instanceof UnknownModelTagError) {
    return `${error.message} Neue Tags zuerst in models/tags.json eintragen und mit models:tags:publish veröffentlichen.`;
  }
  return error instanceof Error ? error.message : fallback;
}
