import {type RuntimeDatabase} from "../../../../db/database.js";
import {ListPlugins, SetPluginEnabled} from "../../domain/usecases/plugin-usecases.js";
import {type PluginRoutesOptions} from "./local-plugin-routes.js";
import {SQLitePluginActivationStore} from "./sqlite-plugin-activation-store.js";

/** Der Katalog kommt von außen, weil der Kern die Integrationen nicht kennt. */
export function createPluginRoutesOptions(
  database: RuntimeDatabase, catalog: readonly string[], notifier: PluginRoutesOptions["notifier"],
): PluginRoutesOptions {
  const activation = new SQLitePluginActivationStore(database);
  return {
    list: new ListPlugins(catalog, activation),
    setEnabled: new SetPluginEnabled(catalog, activation),
    notifier,
  };
}
