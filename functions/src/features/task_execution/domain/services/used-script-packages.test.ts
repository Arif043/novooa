import assert from "node:assert/strict";
import test from "node:test";
import {scriptPackageListsOf} from "./used-script-packages.js";

test("collects the package lists of scripts, also in branches and loops", () => {
  const script = (id: string, packages: string[]) => ({id, primitive: "script", config: {primitive: "script", packages}});
  const graph = {nodes: [
    script("a", ["Pandas"]),
    script("leer", []),
    {id: "c", primitive: "conditionalFlow", config: {primitive: "conditionalFlow", branches: [
      {graph: {nodes: [script("b", ["six==1.16.0"])], edges: []}},
    ]}},
    {id: "f", primitive: "forEach", config: {primitive: "forEach", graph: {nodes: [script("d", ["numpy"])], edges: []}}},
  ]};

  assert.deepEqual(scriptPackageListsOf(graph), [["pandas"], ["six==1.16.0"], ["numpy"]]);
});
