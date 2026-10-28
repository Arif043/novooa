import {type LlmGateway, type LlmRequest, type LlmResponse} from "../../../domain/prompting/llm-gateway.js";
import {withTranslatedGenkitErrors} from "../../errors/genkit-error-translator.js";

/** Decorator: Genkit- und Anbieterfehler werden zu unseren Sprachmodell-Fehlern übersetzt. */
export class ErrorTranslatingLlmGateway<Binding> implements LlmGateway<Binding> {
  constructor(private readonly inner: LlmGateway<Binding>) {}

  generate(request: LlmRequest<Binding>): Promise<LlmResponse> {
    return withTranslatedGenkitErrors(() => this.inner.generate(request));
  }
}
