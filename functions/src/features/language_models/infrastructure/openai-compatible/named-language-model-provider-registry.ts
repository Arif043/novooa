import {type LanguageModelProvider} from "../../domain/entities/language-model.js";
import {abacusLanguageModelProvider} from "../abacus/abacus-language-model-provider.js";
import {huggingFaceLanguageModelProvider} from "../huggingface/huggingface-language-model-provider.js";
import {mistralLanguageModelProvider} from "../mistral/mistral-language-model-provider.js";
import {openRouterLanguageModelProvider} from "../openrouter/openrouter-language-model-provider.js";
import {xAiLanguageModelProvider} from "../xai/xai-language-model-provider.js";
import {type NamedLanguageModelProviderConfiguration} from "./named-language-model-provider.js";

const providers: readonly NamedLanguageModelProviderConfiguration[] = [
  xAiLanguageModelProvider,
  mistralLanguageModelProvider,
  openRouterLanguageModelProvider,
  abacusLanguageModelProvider,
  huggingFaceLanguageModelProvider,
];

export function namedLanguageModelProviderFor(
  provider: LanguageModelProvider,
): NamedLanguageModelProviderConfiguration | undefined {
  return providers.find((configuration) => configuration.provider === provider);
}
