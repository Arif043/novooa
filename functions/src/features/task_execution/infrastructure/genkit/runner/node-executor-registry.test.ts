import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {type NodeExecutor} from "../../../domain/executors/node-executor.js";
import {unavailableScriptExecutorFactory} from "../../local/container-script-executor.js";
import {createDefaultNodeExecutorRegistry, executorFor, NodeExecutorRegistry} from "./node-executor-registry.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

const dependencies = {
  ai: genkit({}),
  logger: silentLogger,
  scriptExecutorFactory: unavailableScriptExecutorFactory(),
};

test("die Standard-Registry kennt jeden eingebauten Executor", () => {
  const registry = createDefaultNodeExecutorRegistry();
  for (const primitive of ["stringInput", "script", "prompt", "conditionalFlow", "forEach", "sendChannelMessage", "httpRequest", "readWebhook"] as const) {
    assert.equal(registry.resolve(primitive, dependencies)?.primitive, primitive);
  }
});

test("ein registrierter Executor ersetzt den eingebauten, ohne den Dispatch zu ändern", () => {
  const replacement = {primitive: "stringInput", execute: () => Promise.reject(new Error("ersetzt"))} as NodeExecutor;
  const registry = createDefaultNodeExecutorRegistry().register(replacement);
  assert.equal(executorFor("stringInput", dependencies.ai, silentLogger, undefined, undefined, undefined, undefined, registry), replacement);
});

test("unbekannte Bausteine liefern keinen Executor", () => {
  assert.equal(new NodeExecutorRegistry().resolve("stringInput", dependencies), undefined);
});
