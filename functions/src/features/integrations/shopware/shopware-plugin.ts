import {type IntegrationPlugin} from "../integration-plugin.js";
import {ShopwareActionRegistry} from "./domain/shopware-action.js";
import {getOrderAction} from "./actions/get-order-action.js";
import {changeOrderStatusAction} from "./actions/change-order-status-action.js";
import {searchProductsAction} from "./actions/search-products-action.js";
import {updateProductAction} from "./actions/update-product-action.js";
import {searchCustomersAction} from "./actions/search-customers-action.js";
import {queryAction} from "./actions/query-action.js";
import {searchOrdersAction} from "./actions/search-orders-action.js";
import {createShopwareNodeExecutor} from "./infrastructure/shopware-node-executor.js";

/** Alle Aktionen des Shopware-Bausteins; jede liegt in `actions/` und meldet sich hier an. */
export const shopwareActions = new ShopwareActionRegistry()
  .register(searchOrdersAction)
  .register(getOrderAction)
  .register(changeOrderStatusAction)
  .register(searchProductsAction)
  .register(updateProductAction)
  .register(searchCustomersAction)
  .register(queryAction);

export const shopwarePlugin: IntegrationPlugin = {
  id: "shopware",
  executors: [createShopwareNodeExecutor(shopwareActions)],
};
