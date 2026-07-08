import {type WorkflowNode} from "../task-runner/task-definition.js";

export function refinementConfigFor(
  node: WorkflowNode,
): RefinementConfig | undefined {
  if (node.config?.primitive !== "iterativeRefinement") return undefined;
  return node.config;
}

type RefinementConfig = Extract<
  WorkflowNode["config"],
  {primitive: "iterativeRefinement"}
>;
