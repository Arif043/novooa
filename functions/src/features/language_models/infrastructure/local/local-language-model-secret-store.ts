import {type RuntimeExecutor} from "../../../../db/database.js";

export interface LocalLanguageModelSecretStore {
  read(secretRef: string): Promise<string | null>;
  write(secretRef: string, value: string): Promise<void>;
  delete(secretRef: string): Promise<void>;
}

export interface TransactionalLanguageModelSecretStore extends LocalLanguageModelSecretStore {
  withDatabase(database: RuntimeExecutor): LocalLanguageModelSecretStore;
}
