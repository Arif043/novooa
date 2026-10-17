import {
  ModelEmptyResponseError,
  ModelResponseTruncatedError,
  type LanguageModelError,
} from "../errors/language-model-errors.js";
import {type NativeOllamaChatResponse} from "./native-ollama-chat-client.js";

/**
 * Erkennt Antworten, mit denen der Baustein nichts anfangen kann. Abgeschnittener Freitext bleibt
 * erlaubt (die Nutzer:in hat die Länge vielleicht bewusst begrenzt); abgeschnittenes JSON nie.
 */
export function ollamaResponseProblem(
  response: NativeOllamaChatResponse,
  expectsJson: boolean,
): LanguageModelError | undefined {
  const empty = response.content.trim().length === 0;
  if (response.doneReason === "length" && (empty || expectsJson)) return truncated(response, empty);
  if (empty) return emptyResponse(response);
  return undefined;
}

function truncated(response: NativeOllamaChatResponse, empty: boolean): ModelResponseTruncatedError {
  const reason = response.thinking.length > 0 && empty
    ? "Das Modell hat beim Nachdenken das Kontextfenster bzw. die maximale Antwortlänge aufgebraucht und keine Antwort geschrieben."
    : "Die Antwort wurde abgeschnitten, weil das Kontextfenster bzw. die maximale Antwortlänge erschöpft war.";
  return new ModelResponseTruncatedError(`${reason} Kontextfenster oder Antwortlänge erhöhen oder Nachdenken abschalten.`);
}

function emptyResponse(response: NativeOllamaChatResponse): ModelEmptyResponseError {
  return new ModelEmptyResponseError(response.thinking.length > 0
    ? "Das Modell hat nur nachgedacht und keine Antwort geschrieben."
    : "Das Modell hat eine leere Antwort geliefert.");
}
