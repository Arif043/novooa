import {eq, getTableColumns} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {languageModelConnections, languageModels} from "../../../../db/schema.js";

/** Modelle erben die Teamzuordnung ihrer Verbindung; sie speichern keine eigene Kopie. */
export function languageModelsQuery(database: RuntimeExecutor) {
  return database.select({...getTableColumns(languageModels), team_id: languageModelConnections.team_id})
    .from(languageModels).innerJoin(languageModelConnections,
      eq(languageModels.connection_id, languageModelConnections.id));
}
