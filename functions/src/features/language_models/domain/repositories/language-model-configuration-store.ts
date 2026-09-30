import {
  type LanguageModel,
  type LanguageModelConnection,
} from "../entities/language-model.js";

export type SaveLanguageModelConfiguration = {
  teamId: string;
  connection: Omit<LanguageModelConnection, "id" | "teamId">;
  model: Omit<LanguageModel, "id" | "teamId" | "connectionId">;
  apiKey: string;
};

export type SaveLanguageModelConnectionConfiguration = {
  teamId: string;
  connection: Omit<LanguageModelConnection, "id" | "teamId">;
  models: Array<Omit<LanguageModel, "id" | "teamId" | "connectionId">>;
  apiKey: string;
};

export interface LanguageModelConfigurationStore {
  list(teamId: string): Promise<LanguageModel[]>;
  save(input: SaveLanguageModelConfiguration): Promise<LanguageModel>;
  saveConnection(input: SaveLanguageModelConnectionConfiguration): Promise<LanguageModel[]>;
  listConnections(teamId: string): Promise<LanguageModelConnection[]>;
  deleteConnection(teamId: string, connectionId: string): Promise<void>;
}
