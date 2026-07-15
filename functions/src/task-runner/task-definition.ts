import {z} from "genkit";

export const workflowPrimitiveSchema = z.enum([
  "stringInput",
  "script",
  "prompt",
  "conditionalFlow",
  "iterativeRefinement",
  "writeFile",
  "readFile",
  "readEmail",
  "toolCall",
  "humanApproval",
  "validation",
]);

export const promptOutputTypeSchema = z.enum(["text", "decision"]);

export const nodeAttachmentSchema = z.object({
  id: z.string().min(1),
  storagePath: z.string().min(1),
  generation: z.string().min(1),
  displayName: z.string().min(1),
  contentType: z.string().default("application/octet-stream"),
  sizeBytes: z.number().int().nonnegative().default(0),
});

export const knowledgeAttachmentSchema = z.object({
  knowledgeBaseId: z.string().min(1).default("default"),
  noteId: z.string().min(1),
  title: z.string().min(1),
  path: z.string().default(""),
  type: z.enum(["atomic", "moc", "unknown"]).default("unknown"),
});

export const stringInputNodeConfigSchema = z.object({
  primitive: z.literal("stringInput").default("stringInput"),
  value: z.string().default(""),
});

export const scriptNodeConfigSchema = z.object({
  primitive: z.literal("script").default("script"),
  script: z.string().default("output = input"),
  attachments: z.array(nodeAttachmentSchema).default([]),
});

export const promptNodeConfigSchema = z.object({
  primitive: z.literal("prompt").default("prompt"),
  instruction: z.string().default(""),
  outputType: promptOutputTypeSchema.default("text"),
  choices: z.array(z.string()).default([]),
  firstChoice: z.string().default(""),
  secondChoice: z.string().default(""),
  attachments: z.array(nodeAttachmentSchema).default([]),
  knowledgeAttachments: z.array(knowledgeAttachmentSchema).default([]),
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

export const humanApprovalNodeConfigSchema = z.object({
  primitive: z.literal("humanApproval").default("humanApproval"),
  instruction: z.string().default("Prüfe das Ergebnis und gib es frei."),
  reviewScope: z.enum(["currentInput", "executionTrace"]).default("currentInput"),
});

export const writeFileNodeConfigSchema = z.object({
  primitive: z.literal("writeFile").default("writeFile"),
  fileName: z.string().max(240).default(""),
  contentType: z.string().max(120).default(""),
  fileId: z.string().optional(),
});

export const readFileNodeConfigSchema = z.object({
  primitive: z.literal("readFile").default("readFile"),
  file: nodeAttachmentSchema.optional(),
});

export const readEmailNodeConfigSchema = z.object({
  primitive: z.literal("readEmail").default("readEmail"),
});

export const nodeConfigSchema = z.discriminatedUnion("primitive", [
  stringInputNodeConfigSchema,
  scriptNodeConfigSchema,
  promptNodeConfigSchema,
  conditionalNodeConfigSchema,
  iterativeRefinementNodeConfigSchema,
  humanApprovalNodeConfigSchema,
  writeFileNodeConfigSchema,
  readFileNodeConfigSchema,
  readEmailNodeConfigSchema,
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
  taskId: z.string().min(1),
  context: z.string().default(""),
});

export const nodeOutputValueSchema = z.object({
  type: z.enum(["string", "datetime", "number", "boolean", "json"]),
  value: z.unknown(),
});

export const nodeExecutionResultSchema = z.object({
  nodeId: z.string(),
  primitive: workflowPrimitiveSchema,
  status: z.enum(["executed", "skipped", "waitingForApproval"]),
  outputs: z.record(z.string(), nodeOutputValueSchema).default({}),
  variables: z.record(z.string(), z.unknown()).optional(),
  selectedNodeId: z.string().nullable().optional(),
  selectedBranchId: z.string().nullable().optional(),
  selectedBranchLabel: z.string().nullable().optional(),
  message: z.string().optional(),
});

export const taskResumeStateSchema = z.object({
  nodeResults: z.array(nodeExecutionResultSchema),
  variables: z.record(z.string(), z.unknown()).default({}),
  remainingNodeIds: z.array(z.string()),
  skippedNodeIds: z.array(z.string()),
  waitingNodeId: z.string().optional(),
});

const completedTaskGraphOutputSchema = z.object({
  status: z.literal("completed"),
  taskId: z.string(),
  finalOutput: z.string(),
  nodeResults: z.array(nodeExecutionResultSchema),
});

const waitingTaskGraphOutputSchema = z.object({
  status: z.literal("waitingForApproval"),
  taskId: z.string(),
  finalOutput: z.string(),
  nodeResults: z.array(nodeExecutionResultSchema),
  resumeState: taskResumeStateSchema,
});

export const taskGraphOutputSchema = z.discriminatedUnion("status", [
  completedTaskGraphOutputSchema,
  waitingTaskGraphOutputSchema,
]);

export const runTaskDefinitionOutputSchema = z.object({
  runId: z.string().min(1),
  taskId: z.string().min(1),
  status: z.literal("queued"),
});

export const reviewTaskRunInputSchema = z.object({
  runId: z.string().min(1),
  decision: z.enum(["approve", "reject"]),
  output: z.string().default(""),
});

export const reviewTaskRunOutputSchema = z.object({
  runId: z.string().min(1),
  status: z.enum(["queued", "rejected"]),
});

export type WorkflowNode = z.infer<typeof workflowNodeSchema>;
export type WorkflowEdge = z.infer<typeof workflowEdgeSchema>;
export type NodeAttachment = z.infer<typeof nodeAttachmentSchema>;
export type KnowledgeAttachment = z.infer<typeof knowledgeAttachmentSchema>;
export type TaskDefinition = z.infer<typeof taskDefinitionSchema>;
export type TaskGraphInput = {
  taskDefinition: TaskDefinition;
  context: string;
  teamId: string;
  input?: Record<string, unknown>;
};
export type RunTaskDefinitionInput = z.infer<
  typeof runTaskDefinitionInputSchema
>;
export type TaskGraphOutput = z.infer<
  typeof taskGraphOutputSchema
>;
export type CompletedTaskGraphOutput = z.infer<
  typeof completedTaskGraphOutputSchema
>;
export type WaitingTaskGraphOutput = z.infer<
  typeof waitingTaskGraphOutputSchema
>;
export type TaskResumeState = z.infer<typeof taskResumeStateSchema>;
export type RunTaskDefinitionOutput = z.infer<
  typeof runTaskDefinitionOutputSchema
>;
export type ReviewTaskRunInput = z.infer<typeof reviewTaskRunInputSchema>;
export type ReviewTaskRunOutput = z.infer<typeof reviewTaskRunOutputSchema>;
export type NodeExecutionResult = z.infer<typeof nodeExecutionResultSchema>;
export type NodeOutputValue = z.infer<typeof nodeOutputValueSchema>;
