import assert from "node:assert/strict";
import test from "node:test";
import {valueAtJsonPointer} from "../services/json-pointer.js";
import {modelInputFromWorkflowMapping} from "../services/model-input-from-workflow-mapping.js";
import {readFileNodeExecutor} from "./read-file-node-executor.js";
import {saveDocumentNodeExecutor} from "./save-document-node-executor.js";
import {tableFromCollectionNodeExecutor} from "./table-from-collection-node-executor.js";

// Codes aus `node-failures.ts`, die die Executor-Tests nicht schon abdecken.

const resolveValue = (template: string) => template === "{{fehlt}}" ? undefined : template;
const context = {teamId: "team-1", templateExpressionResolver: {resolveValue, resolveText: resolveValue}} as never;

test("a node with the configuration of another block is configurationMissing", async () => {
  const node = {id: "n", primitive: "tableFromCollection", config: {primitive: "readFile"}} as never;

  const failure = (await tableFromCollectionNodeExecutor.execute(node, context))._unsafeUnwrapErr();

  assert.deepEqual([failure.code, failure.details], ["configurationMissing", {primitive: "tableFromCollection"}]);
});

test("reading without a selected file is settingMissing inputFile", async () => {
  const node = {id: "n", primitive: "readFile", config: {primitive: "readFile"}} as never;

  const failure = (await readFileNodeExecutor.execute(node, context))._unsafeUnwrapErr();

  assert.deepEqual(failure.details, {setting: "inputFile"});
});

test("saving a field twice or with an unresolved value is settingInvalid", async () => {
  const twice = {primitive: "saveDocument", collectionName: "k", filters: [], fields: [
    {field: "a", value: "1"}, {field: "a", value: "2"},
  ]};
  const unresolved = {...twice, fields: [{field: "a", value: "{{fehlt}}"}]};
  const save = (config: object) => saveDocumentNodeExecutor.execute({id: "n", primitive: "saveDocument", config} as never, context);

  assert.deepEqual((await save(twice))._unsafeUnwrapErr().details, {setting: "documentFieldDuplicate"});
  assert.deepEqual((await save(unresolved))._unsafeUnwrapErr().details, {setting: "documentFieldValue", name: "a"});
});

test("a JSON pointer without a leading slash is settingInvalid", () => {
  assert.deepEqual(valueAtJsonPointer({}, "items")._unsafeUnwrapErr().details, {setting: "jsonPointer", name: "items"});
});

test("values that do not fit the tensor shape are tensorShapeMismatch", async () => {
  const mapping = {modelInputName: "eingabe", workflowMapping: "", sourceType: "tensor", dataType: "float32", shape: [3]} as never;

  const failure = (await modelInputFromWorkflowMapping(mapping, [1, 2], "team-1", {} as never))._unsafeUnwrapErr();

  assert.deepEqual([failure.code, failure.details], ["tensorShapeMismatch", {name: "eingabe"}]);
});
