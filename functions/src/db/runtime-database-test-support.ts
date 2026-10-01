import {resolve} from "node:path";
import {type TestContext} from "node:test";
import {openLocalRuntimeDatabase} from "../shared/local/local-runtime-database.js";
import {teams} from "./schema.js";

export async function runtimeTestDatabase(t: TestContext) {
  const database = await openLocalRuntimeDatabase({databasePath: ":memory:",
    migrationsDirectory: resolve(__dirname, "../../drizzle")});
  t.after(() => database.$client.close());
  await database.insert(teams).values({id: "team-1", name: "Testteam", owner_uid: "user-1"});
  return database;
}
