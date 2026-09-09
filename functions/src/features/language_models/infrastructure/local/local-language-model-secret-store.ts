export interface LocalLanguageModelSecretStore {
  read(secretRef: string): Promise<string | null>;
  write(secretRef: string, value: string): Promise<void>;
  delete(secretRef: string): Promise<void>;
}
