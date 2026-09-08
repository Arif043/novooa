export interface LocalLanguageModelSecretStore {
  read(secretRef: string): Promise<string | null>;
}
