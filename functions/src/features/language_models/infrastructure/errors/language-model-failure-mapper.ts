import {
  LanguageModelFailure,
  type LanguageModelFailureCode,
} from "../../domain/entities/language-model-failure.js";
import {
  ModelCapabilityMissingError,
  ModelEmptyResponseError,
  ModelOutputSchemaError,
  ModelProviderUnavailableError,
  ModelRequestRejectedError,
  ModelResponseTruncatedError,
  ModelTimeoutError,
  type LanguageModelError,
} from "./language-model-errors.js";

type ErrorType = abstract new (...args: never[]) => LanguageModelError;

const codesByError: ReadonlyArray<[ErrorType, LanguageModelFailureCode]> = [
  [ModelOutputSchemaError, "outputSchemaViolated"],
  [ModelResponseTruncatedError, "responseTruncated"],
  [ModelEmptyResponseError, "emptyResponse"],
  [ModelProviderUnavailableError, "providerUnavailable"],
  [ModelRequestRejectedError, "requestRejected"],
  [ModelTimeoutError, "timedOut"],
  [ModelCapabilityMissingError, "capabilityMissing"],
];

/**
 * Bildet unsere Exceptions auf eine Failure ab. Framework-Fehler sind hier schon übersetzt
 * (`withTranslatedGenkitErrors`); alles Übrige wird `unknown`.
 */
export function languageModelFailureFrom(error: unknown): LanguageModelFailure {
  const code = codesByError.find(([ErrorType]) => error instanceof ErrorType)?.[1] ?? "unknown";
  return new LanguageModelFailure(code, messageOf(error));
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
