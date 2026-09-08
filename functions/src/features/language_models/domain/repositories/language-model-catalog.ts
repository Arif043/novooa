import {
  type LanguageModel,
  type LanguageModelConnection,
} from "../entities/language-model.js";

export interface LanguageModelCatalog {
  loadModel(teamId: string, modelId: string): Promise<LanguageModel>;
  loadConnection(
    teamId: string,
    connectionId: string,
  ): Promise<LanguageModelConnection>;
  loadConnectionApiKey(
    teamId: string,
    connectionId: string,
  ): Promise<string>;
}
