import {z} from "genkit";

export const workflowPrimitiveSchema = z.enum([
  "stringInput",
  "prompt",
  "conditionalFlow",
  "iterativeRefinement",
  "toolCall",
  "humanApproval",
  "validation",
]);

export const promptOutputTypeSchema = z.enum(["text", "decision"]);

export const stringInputNodeConfigSchema = z.object({
  primitive: z.literal("stringInput").default("stringInput"),
  value: z.string().default(""),
});

export const promptNodeConfigSchema = z.object({
  primitive: z.literal("prompt").default("prompt"),
  instruction: z.string().default(""),
  outputType: promptOutputTypeSchema.default("text"),
  choices: z.array(z.string()).default([]),
  firstChoice: z.string().default(""),
  secondChoice: z.string().default(""),
});

export const workflowEdgeSchema = z.object({
  from: z.string().min(1),
  to: z.string().min(1),
  conditionLabel: z.string().optional(),
});

const branchWorkflowNodeSchema = z.object({
  id: z.string().min(1),
  primitive: workflowPrimitiveSchema,
  title: z.string().min(1),
  description: z.string().default(""),
  config: z.unknown().optional(),
});

const branchWorkflowGraphSchema = z.object({
  nodes: z.array(branchWorkflowNodeSchema).default([]),
  edges: z.array(workflowEdgeSchema).default([]),
});

export const conditionalBranchSchema = z.object({
  id: z.string().min(1),
  label: z.string().default(""),
  nodeIds: z.array(z.string().min(1)).default([]),
  graph: branchWorkflowGraphSchema.default({nodes: [], edges: []}),
});

export const conditionalNodeConfigSchema = z.object({
  primitive: z.literal("conditionalFlow").default("conditionalFlow"),
  choices: z.array(z.string()).default([]),
  branches: z.array(conditionalBranchSchema).default([]),
});

export const iterativeRefinementNodeConfigSchema = z.object({
  primitive: z.literal("iterativeRefinement").default("iterativeRefinement"),
  optimizerPrompt: z.string().default(""),
  critiquePrompt: z.string().default(""),
  maxIterations: z.number().int().min(1).max(5).default(2),
});

export const nodeConfigSchema = z.discriminatedUnion("primitive", [
  stringInputNodeConfigSchema,
  promptNodeConfigSchema,
  conditionalNodeConfigSchema,
  iterativeRefinementNodeConfigSchema,
]);

export const workflowNodeSchema = z.object({
  id: z.string().min(1),
  primitive: workflowPrimitiveSchema,
  title: z.string().min(1),
  description: z.string().default(""),
  config: nodeConfigSchema,
});

export const taskDefinitionSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  objective: z.string().default(""),
  nodes: z.array(workflowNodeSchema).min(1),
  edges: z.array(workflowEdgeSchema).default([]),
});

export const runTaskDefinitionInputSchema = z.object({
  taskDefinition: taskDefinitionSchema,
  context: z.string().default(""),
});

export const nodeExecutionResultSchema = z.object({
  nodeId: z.string(),
  primitive: workflowPrimitiveSchema,
  status: z.enum(["executed", "skipped"]),
  output: z.string(),
  selectedNodeId: z.string().nullable().optional(),
  selectedBranchId: z.string().nullable().optional(),
  selectedBranchLabel: z.string().nullable().optional(),
  message: z.string().optional(),
});

export const runTaskDefinitionOutputSchema = z.object({
  taskId: z.string(),
  finalOutput: z.string(),
  nodeResults: z.array(nodeExecutionResultSchema),
});

export type WorkflowNode = z.infer<typeof workflowNodeSchema>;
export type WorkflowEdge = z.infer<typeof workflowEdgeSchema>;
export type TaskDefinition = z.infer<typeof taskDefinitionSchema>;
export type RunTaskDefinitionInput = z.infer<
  typeof runTaskDefinitionInputSchema
>;
export type RunTaskDefinitionOutput = z.infer<
  typeof runTaskDefinitionOutputSchema
>;
export type NodeExecutionResult = z.infer<typeof nodeExecutionResultSchema>;
