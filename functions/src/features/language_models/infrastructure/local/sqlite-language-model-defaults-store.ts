import {type LocalSqlDatabase, type SqlRow} from "../../../../shared/local/local-sql-database.js";
import {
  emptyLanguageModelDefaults,
  type LanguageModelDefaults,
} from "../../domain/entities/language-model-defaults.js";
import {type LanguageModelDefaultsStore} from "../../domain/repositories/language-model-defaults-store.js";

type DefaultsRow = SqlRow & {
  block_model_id: string | null;
  assistant_model_id: string | null;
};

export class SQLiteLanguageModelDefaultsStore implements LanguageModelDefaultsStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async loadDefaults(teamId: string): Promise<LanguageModelDefaults> {
    const row = await this.database.get<DefaultsRow>(
      "SELECT block_model_id, assistant_model_id FROM language_model_defaults WHERE team_id = ?",
      [teamId],
    );
    if (!row) return emptyLanguageModelDefaults;
    return {
      blockModelId: row.block_model_id,
      assistantModelId: row.assistant_model_id,
    };
  }

  async saveDefaults(teamId: string, defaults: LanguageModelDefaults): Promise<void> {
    await this.database.run(
      `INSERT INTO language_model_defaults (team_id, block_model_id, assistant_model_id)
       VALUES (?, ?, ?)
       ON CONFLICT(team_id) DO UPDATE SET
         block_model_id = excluded.block_model_id,
         assistant_model_id = excluded.assistant_model_id`,
      [teamId, defaults.blockModelId, defaults.assistantModelId],
    );
  }
}
