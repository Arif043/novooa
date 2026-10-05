import {type IntegrationPlugin} from "../integration-plugin.js";
import {ShopwareActionRegistry} from "./domain/shopware-action.js";
import {searchOrdersAction} from "./actions/search-orders-action.js";
import {createShopwareNodeExecutor} from "./infrastructure/shopware-node-executor.js";

/** Alle Aktionen des Shopware-Bausteins; jede liegt in `actions/` und meldet sich hier an. */
export const shopwareActions = new ShopwareActionRegistry().register(searchOrdersAction);

export const shopwarePlugin: IntegrationPlugin = {
  id: "shopware",
  executors: [createShopwareNodeExecutor(shopwareActions)],
};
