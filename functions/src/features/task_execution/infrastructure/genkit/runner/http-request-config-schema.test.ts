import assert from "node:assert/strict";
import test from "node:test";
import {taskDefinitionSchema} from "./task-definition.js";

const taskWith = (config: unknown) => ({
  id: "t", title: "T", objective: "",
  nodes: [{id: "n", primitive: "httpRequest", title: "Anfrage", description: "", outputName: "antwort", config}],
  edges: [],
});

test("die Aufgabendefinition kennt den HTTP-Baustein und ergänzt Standardwerte", () => {
  const parsed = taskDefinitionSchema.parse(taskWith({primitive: "httpRequest", url: "/orders"}));

  assert.deepEqual(parsed.nodes[0]?.config, {
    primitive: "httpRequest", url: "/orders", method: "GET", query: [], headers: [], bodyType: "none", body: "",
    timeoutSeconds: 30, failOnHttpError: true,
  });
});

test("ungültige Methoden, Zeitlimits und Body-Arten werden abgelehnt", () => {
  for (const config of [
    {primitive: "httpRequest", method: "TRACE"},
    {primitive: "httpRequest", timeoutSeconds: 0},
    {primitive: "httpRequest", timeoutSeconds: 121},
    {primitive: "httpRequest", bodyType: "xml"},
  ]) assert.throws(() => taskDefinitionSchema.parse(taskWith(config)), /./, JSON.stringify(config));
});
