import {filesystem, skills} from "@genkit-ai/middleware";
import {type GenerateOptions} from "genkit";
import {languageModelRetry} from "../../../../../language_models/infrastructure/genkit/language-model-retry.js";

type Middleware = NonNullable<GenerateOptions["use"]>;

/**
 * Orchestrator und Mitarbeiter teilen einen Arbeitsordner mit Schreibrecht; die Middleware lässt keine
 * Pfade außerhalb zu, und der Ordner verschwindet nach dem Lauf. Fähigkeiten bekommt nur ihr Mitarbeiter.
 */
export function teamworkMiddleware(rootDirectory: string, skillsDirectory?: string): Middleware {
  const middleware: Middleware = [
    languageModelRetry(),
    filesystem({rootDirectory, allowWriteAccess: true}),
  ];
  if (skillsDirectory) middleware.push(skills({skillPaths: [skillsDirectory]}));
  return middleware;
}
