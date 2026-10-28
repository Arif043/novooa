import {type LlmGateway} from "../../../domain/prompting/llm-gateway.js";
import {type PromptRenderer} from "../../../domain/prompting/prompt-renderer.js";
import {XmlPromptRenderer} from "../../../domain/prompting/xml-prompt-renderer.js";
import {ErrorTranslatingLlmGateway} from "./error-translating-llm-gateway.js";
import {type GenkitLlmBinding} from "./genkit-llm-binding.js";
import {GenkitLlmGateway} from "./genkit-llm-gateway.js";
import {type LlmCallLog} from "./llm-call-log.js";
import {LoggingLlmGateway} from "./logging-llm-gateway.js";

/**
 * Setzt den Gateway zusammen: Fehlerübersetzung außen (auch Protokollfehler werden übersetzt),
 * darin das Protokoll, innen der Genkit-Aufruf. Retry läuft als Middleware je Modellanfrage.
 */
export function createLlmGateway(
  log: LlmCallLog,
  renderer: PromptRenderer = new XmlPromptRenderer(),
): LlmGateway<GenkitLlmBinding> {
  return new ErrorTranslatingLlmGateway(
    new LoggingLlmGateway(new GenkitLlmGateway(renderer), renderer, log),
  );
}
