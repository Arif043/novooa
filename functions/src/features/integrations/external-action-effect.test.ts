import assert from "node:assert/strict";
import test from "node:test";
import {RunEffectRecorder} from "../task_execution/domain/services/run-effect-recorder.js";
import {uploadAction} from "./google_drive/actions/upload-action.js";
import {readAction} from "./google_drive/actions/read-action.js";
import {changeOrderStatusAction} from "./shopware/actions/change-order-status-action.js";
import {searchOrdersAction} from "./shopware/actions/search-orders-action.js";
import {updateProductAction} from "./shopware/actions/update-product-action.js";
import {recordExternalAction} from "./external-action-effect.js";

const recorder = () => RunEffectRecorder.root().child("shop");

test("a changed order status is an external action labelled with order number and new status", () => {
  const effects = recorder();

  recordExternalAction(effects, "shopware", changeOrderStatusAction, {
    value: {type: "json", value: {orderNumber: "10042"}},
    newStatus: {type: "string", value: "completed"},
    changed: {type: "boolean", value: true},
  });

  assert.deepEqual(effects.effects, [{
    kind: "externalAction", plugin: "shopware", action: "changeOrderStatus", label: "10042: completed", sourceNodeId: "shop",
  }]);
});

test("an action that changed nothing, and reading actions, report no effect", () => {
  const effects = recorder();
  const unchanged = {value: {type: "json" as const, value: {productNumber: "SW-1"}}, changed: {type: "boolean" as const, value: false}};

  recordExternalAction(effects, "shopware", updateProductAction, unchanged);
  recordExternalAction(effects, "shopware", searchOrdersAction, {value: {type: "json", value: []}});
  recordExternalAction(effects, "googleDrive", readAction, {name: {type: "string", value: "a.pdf"}});

  assert.equal(effects.effects.length, 0);
});

test("an upload to Google Drive is labelled with the file name", () => {
  const effects = recorder();

  recordExternalAction(effects, "googleDrive", uploadAction, {name: {type: "string", value: "Bericht.pdf"}});

  assert.equal(effects.effects[0]?.kind === "externalAction" && effects.effects[0].label, "Bericht.pdf");
});
