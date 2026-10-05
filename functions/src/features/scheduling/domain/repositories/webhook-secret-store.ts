import {type RuntimeExecutor} from "../../../../db/database.js";

/** Verschlüsselter Geheimnisspeicher; in der Runtime derselbe wie bei Sprachmodellen und Verbindungen. */
export interface WebhookSecretStore {
  read(secretRef: string): Promise<string | null>;
  write(secretRef: string, value: string): Promise<void>;
  delete(secretRef: string): Promise<void>;
  withDatabase(database: RuntimeExecutor): Omit<WebhookSecretStore, "withDatabase">;
}

export function webhookSecretRef(teamId: string, triggerId: string): string {
  return `webhook/${teamId}/${triggerId}`;
}
