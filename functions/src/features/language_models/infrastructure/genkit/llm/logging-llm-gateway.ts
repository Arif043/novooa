import {type LlmGateway, type LlmRequest, type LlmResponse} from "../../../domain/prompting/llm-gateway.js";
import {type PromptRenderer} from "../../../domain/prompting/prompt-renderer.js";
import {type GenkitLlmBinding} from "./genkit-llm-binding.js";
import {type LlmCallLog} from "./llm-call-log.js";

/**
 * Decorator: protokolliert jeden Aufruf mit dem gerenderten Prompt und der Antwort. Scheitert der
 * Aufruf, bleibt nur der Start im Protokoll — den Fehler meldet die Aufrufstelle.
 */
export class LoggingLlmGateway implements LlmGateway<GenkitLlmBinding> {
  constructor(
    private readonly inner: LlmGateway<GenkitLlmBinding>,
    private readonly renderer: PromptRenderer,
    private readonly log: LlmCallLog,
    private readonly now: () => number = Date.now,
  ) {}

  async generate(request: LlmRequest<GenkitLlmBinding>): Promise<LlmResponse> {
    const rendered = this.renderer.render(request.prompt);
    const imageCall = request.output.kind === "image";
    this.log.started({
      label: request.label, model: request.binding.logContext, system: rendered.system, user: rendered.user,
      output: request.output, mediaCount: request.prompt.mediaUrls.length,
      options: imageCall ? {} : request.binding.config,
    });
    const startedAt = this.now();
    const response = await this.inner.generate(request);
    this.log.finished({
      label: request.label, durationMs: this.now() - startedAt, text: response.text,
      data: response.data, mediaUrl: response.mediaUrl,
    });
    return response;
  }
}
