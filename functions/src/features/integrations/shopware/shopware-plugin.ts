import {type IntegrationPlugin} from "../integration-plugin.js";
import {ShopwareActionRegistry} from "./domain/shopware-action.js";
import {getOrderAction} from "./actions/get-order-action.js";
import {changeOrderStatusAction} from "./actions/change-order-status-action.js";
import {searchProductsAction} from "./actions/search-products-action.js";
import {updateProductAction} from "./actions/update-product-action.js";
import {searchCustomersAction} from "./actions/search-customers-action.js";
import {readEventAction} from "./actions/read-event-action.js";
import {queryAction} from "./actions/query-action.js";
import {searchOrdersAction} from "./actions/search-orders-action.js";
import {createShopwareNodeExecutor} from "./infrastructure/shopware-node-executor.js";
import {shopwareTriggerParamsFrom, shopwareTriggerProblem} from "./triggers/shopware-trigger-params.js";
import {ShopwareTriggerInterpreter} from "./triggers/shopware-trigger-interpreter.js";
import {generateWebhookToken} from "../../scheduling/domain/entities/webhook-config.js";

/** Alle Aktionen des Shopware-Bausteins; jede liegt in `actions/` und meldet sich hier an. */
export const shopwareActions = new ShopwareActionRegistry()
  .register(searchOrdersAction)
  .register(getOrderAction)
  .register(changeOrderStatusAction)
  .register(searchProductsAction)
  .register(updateProductAction)
  .register(searchCustomersAction)
  .register(queryAction)
  .register(readEventAction);

export const shopwarePlugin: IntegrationPlugin = {
  id: "shopware",
  executors: () => [createShopwareNodeExecutor(shopwareActions)],
  eventTriggers: [{
    source: {
      id: "shopware",
      usesWebhook: true,
      problem: (config) => shopwareTriggerProblem(config.params),
      // Das Token vergibt der Server. Die App-Webhooks von Shopware laufen ohne Signatur; das Token in der Adresse ist der Schutz.
      prepare: (config) => ({
        ...config,
        params: {...shopwareTriggerParamsFrom(config.params)},
        webhook: {token: generateWebhookToken(), verification: {kind: "none"}, validationParameter: ""},
      }),
    },
    interpreter: ({http}) => new ShopwareTriggerInterpreter(http),
  }],
};
