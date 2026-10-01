import {eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {languageModelDefaults} from "../../../../db/schema.js";
import {
  emptyLanguageModelDefaults,
  type LanguageModelDefaults,
} from "../../domain/entities/language-model-defaults.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

export class SQLiteLanguageModelDefaultsStore implements LanguageModelDefaultsStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async loadDefaults(teamId: string): Promise<LanguageModelDefaults> {
    const row = await this.database.select().from(languageModelDefaults).where(eq(languageModelDefaults.team_id, teamId)).get();
    if (!row) return emptyLanguageModelDefaults;
    return {
      blockModelId: row.block_model_id,
      assistantModelId: row.assistant_model_id,
    };
  }

  async saveDefaults(teamId: string, defaults: LanguageModelDefaults): Promise<void> {
    const values = {team_id: teamId, block_model_id: defaults.blockModelId, assistant_model_id: defaults.assistantModelId};
    await this.database.insert(languageModelDefaults).values(values)
      .onConflictDoUpdate({target: languageModelDefaults.team_id, set: values});
  }
}
