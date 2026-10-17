import {openAICompatible} from "@genkit-ai/compat-oai";
import {googleAI} from "@genkit-ai/google-genai";
import {modelRef, type ModelArgument} from "genkit";
import {genkit, type GenkitBeta} from "genkit/beta";
import {type LanguageModelCapabilities} from "../../domain/entities/language-model.js";
import {type LanguageModelCatalog} from "../../domain/repositories/language-model-catalog.js";
import {OllamaLanguageModelCapabilityInspector} from "../ollama/ollama-language-model-capability-inspector.js";
import {nativeOllamaPlugin} from "../ollama/native-ollama-genkit-plugin.js";
import {namedLanguageModelProviderFor} from "../openai-compatible/named-language-model-provider-registry.js";
import {type GenkitGenerationConfig} from "./generation-config/genkit-generation-config.js";
import {googleAiGenerationConfig} from "./generation-config/google-ai-generation-config.js";
import {ollamaGenerationConfig} from "./generation-config/ollama-generation-config.js";
import {openAiCompatibleGenerationConfig} from "./generation-config/open-ai-compatible-generation-config.js";

export type ResolvedGenkitLanguageModel = {
  ai: GenkitBeta;
  model: ModelArgument;
  capabilities: LanguageModelCapabilities;
  logContext: Record<string, string>;
  /** Übersetzt die Generierungsoptionen für genau diesen Anbieter. */
  generationConfig: GenkitGenerationConfig;
};

export interface GenkitLanguageModelResolver {
  resolve(
    teamId: string,
    languageModelId: string,
  ): Promise<ResolvedGenkitLanguageModel>;
}

export class CatalogGenkitLanguageModelResolver
    implements GenkitLanguageModelResolver {
  constructor(
    catalog: LanguageModelCatalog,
    private readonly ollamaCapabilities = new OllamaLanguageModelCapabilityInspector(),
  ) {
    this.#catalog = catalog;
  }

  readonly #catalog: LanguageModelCatalog;

  async resolve(
    teamId: string,
    languageModelId: string,
  ): Promise<ResolvedGenkitLanguageModel> {
    const model = await this.#catalog.loadModel(teamId, languageModelId);
    const connection = await this.#catalog.loadConnection(teamId, model.connectionId);
    if (connection.provider === "elevenLabs") {
      throw new Error("ElevenLabs-Modelle können nur Sprache ausgeben und keine Texte erzeugen.");
    }
    const apiKey = await this.#catalog.loadConnectionApiKey(teamId, connection.id);
    if (connection.provider === "googleAi") {
      return {
        ai: genkit({plugins: [googleAI({apiKey})]}),
        model: googleAI.model(model.modelId),
        capabilities: model.capabilities,
        logContext: {provider: "googleAi", model: model.modelId},
        generationConfig: googleAiGenerationConfig(model.modelId),
      };
    }
    const namedProvider = namedLanguageModelProviderFor(connection.provider);
    const baseUrl = namedProvider?.baseUrl ?? connection.baseUrl;
    if (!baseUrl) throw new Error("Der OpenAI-kompatiblen Verbindung fehlt die Base-URL.");
    if (connection.provider === "ollama") {
      const capabilities = await this.capabilitiesFor(
        connection.provider, baseUrl, model.modelId, model.capabilities,
      );
      const providerName = "language-model-" + connection.id;
      return {
        ai: genkit({plugins: [nativeOllamaPlugin({
          name: providerName,
          serverAddress: nativeServerAddressFor(baseUrl),
          modelId: model.modelId,
        })]}),
        model: modelRef({name: providerName + "/" + model.modelId}),
        capabilities,
        logContext: {provider: "ollama", endpoint: connection.name, model: model.modelId},
        generationConfig: ollamaGenerationConfig,
      };
    }
    const providerName = `language-model-${connection.id}`;
    const capabilities = await this.capabilitiesFor(connection.provider, baseUrl, model.modelId, model.capabilities);
    return {
      ai: genkit({plugins: [openAICompatible({
        name: providerName,
        apiKey,
        baseURL: baseUrl,
      })]}),
      model: modelRef({name: `${providerName}/${model.modelId}`}),
      capabilities,
      logContext: {
        provider: connection.provider,
        endpoint: connection.name,
        model: model.modelId,
      },
      generationConfig: openAiCompatibleGenerationConfig,
    };
  }
  private capabilitiesFor(
    provider: string,
    baseUrl: string,
    modelId: string,
    fallback: LanguageModelCapabilities,
  ): Promise<LanguageModelCapabilities> {
    if (provider !== "ollama") return Promise.resolve(fallback);
    return this.ollamaCapabilities.inspect({baseUrl, fallback, modelId});
  }
}

function nativeServerAddressFor(baseUrl: string): string {
  return new URL(baseUrl).origin;
}
