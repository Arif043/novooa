import {type LanguageModelProvider} from "../../domain/entities/language-model.js";
import {mistralLanguageModelProvider} from "../mistral/mistral-language-model-provider.js";
import {openRouterLanguageModelProvider} from "../openrouter/openrouter-language-model-provider.js";
import {xAiLanguageModelProvider} from "../xai/xai-language-model-provider.js";
import {type NamedLanguageModelProviderConfiguration} from "./named-language-model-provider.js";

const providers: readonly NamedLanguageModelProviderConfiguration[] = [
  xAiLanguageModelProvider,
  mistralLanguageModelProvider,
  openRouterLanguageModelProvider,
];

export function namedLanguageModelProviderFor(
  provider: LanguageModelProvider,
): NamedLanguageModelProviderConfiguration | undefined {
  return providers.find((configuration) => configuration.provider === provider);
}
