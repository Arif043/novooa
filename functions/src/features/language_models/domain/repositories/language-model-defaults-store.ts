import {type LanguageModelDefaults} from "../entities/language-model-defaults.js";

export interface LanguageModelDefaultsStore {
  loadDefaults(teamId: string): Promise<LanguageModelDefaults>;
  saveDefaults(teamId: string, defaults: LanguageModelDefaults): Promise<void>;
}
