import {GenkitError, type StatusName} from "genkit";
import {
  LanguageModelError,
  ModelCapabilityMissingError,
  ModelOutputSchemaError,
  ModelProviderUnavailableError,
  ModelRequestRejectedError,
  ModelTimeoutError,
} from "./language-model-errors.js";
import {missingCapabilityIn} from "./missing-capability-detection.js";

type ErrorType = new (message: string, originalError?: unknown) => LanguageModelError;

const errorsByGenkitStatus: Partial<Record<StatusName, ErrorType>> = {
  DEADLINE_EXCEEDED: ModelTimeoutError,
  UNAVAILABLE: ModelProviderUnavailableError,
  INTERNAL: ModelProviderUnavailableError,
  RESOURCE_EXHAUSTED: ModelRequestRejectedError,
  PERMISSION_DENIED: ModelRequestRejectedError,
  UNAUTHENTICATED: ModelRequestRejectedError,
  NOT_FOUND: ModelRequestRejectedError,
  INVALID_ARGUMENT: ModelRequestRejectedError,
  FAILED_PRECONDITION: ModelRequestRejectedError,
};

/** Führt einen Genkit-Aufruf aus und wirft Framework-Fehler als unsere Exceptions weiter. */
export async function withTranslatedGenkitErrors<T>(call: () => Promise<T>): Promise<T> {
  try {
    return await call();
  } catch (error) {
    throw translateGenkitError(error);
  }
}

/**
 * Wandelt Fehler von Genkit, Anbieter-SDKs und `fetch` in unsere Fehler um. Unsere eigenen bleiben,
 * wie sie sind; was nicht erkannt wird, bleibt der ursprüngliche Fehler.
 */
export function translateGenkitError(error: unknown): unknown {
  if (error instanceof ModelCapabilityMissingError) return error;
  const capability = missingCapabilityIn(error);
  if (capability !== undefined) {
    return new ModelCapabilityMissingError(`Das gewählte Sprachmodell unterstützt ${capability} nicht. Wähle ein anderes Modell.`, error);
  }
  if (error instanceof LanguageModelError) return error;
  if (error instanceof GenkitError) return fromGenkitError(error);
  if (isJsonSyntaxError(error)) return new ModelOutputSchemaError("Die Antwort des Modells war kein gültiges JSON.", error);
  if (isTimeout(error)) return new ModelTimeoutError("Das Sprachmodell hat nicht rechtzeitig geantwortet.", error);
  if (isNetworkFailure(error)) return new ModelProviderUnavailableError("Der Modellanbieter ist nicht erreichbar.", error);
  const status = httpStatusOf(error);
  if (status !== undefined) return fromHttpStatus(status, error);
  return error;
}

function fromGenkitError(error: GenkitError): unknown {
  if (isSchemaViolation(error)) {
    return new ModelOutputSchemaError("Die Antwort des Modells passt nicht zur verlangten Ausgabestruktur.", error);
  }
  const ErrorType = errorsByGenkitStatus[error.status];
  return ErrorType ? new ErrorType(error.originalMessage || error.message, error) : error;
}

function isSchemaViolation(error: GenkitError): boolean {
  return error.status === "INVALID_ARGUMENT" && /schema validation failed/i.test(error.message);
}

function fromHttpStatus(status: number, error: unknown): unknown {
  const message = error instanceof Error ? error.message : `Der Modellanbieter antwortete mit ${status}.`;
  if (status === 408) return new ModelTimeoutError(message, error);
  if (status >= 500) return new ModelProviderUnavailableError(message, error);
  if (status >= 400) return new ModelRequestRejectedError(message, error);
  return error;
}

/** Genkit parst strukturierte Ausgaben mit JSON5; Text statt JSON endet dort als `SyntaxError`. */
function isJsonSyntaxError(error: unknown): boolean {
  return error instanceof SyntaxError && /JSON/i.test(error.message);
}

function isTimeout(error: unknown): boolean {
  return error instanceof Error && (error.name === "TimeoutError" || error.name === "AbortError");
}

function isNetworkFailure(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  return /fetch failed|ECONNREFUSED|ENOTFOUND|EHOSTUNREACH|ECONNRESET/.test(`${error.message} ${String((error as {cause?: unknown}).cause)}`);
}

/** Anbieter-SDKs (OpenAI, Google) hängen den HTTP-Status als `status` an ihre Fehler. */
function httpStatusOf(error: unknown): number | undefined {
  if (!(error instanceof Error) || !("status" in error)) return undefined;
  return typeof error.status === "number" ? error.status : undefined;
}
