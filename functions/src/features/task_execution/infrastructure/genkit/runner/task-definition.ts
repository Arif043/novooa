import {z} from "genkit";
import {
  type NodeOutputValue,
  workflowPrimitives,
} from "../../../domain/entities/task.js";

export const workflowPrimitiveSchema = z.enum(workflowPrimitives);

export const promptOutputTypeSchema = z.enum([
  "text",
  "decision",
  "structured",
  "image",
]);

export const nodeAttachmentSchema = z.object({
  id: z.string().min(1),
  storagePath: z.string().min(1),
  generation: z.string().min(1),
  displayName: z.string().min(1),
  contentType: z.string().default("application/octet-stream"),
  sizeBytes: z.number().int().nonnegative().default(0),
  versionCreatedAt: z.number().int().nonnegative().optional(),
});

export const knowledgeAttachmentSchema = z.object({
  knowledgeBaseId: z.string().min(1).default("default"),
  noteId: z.string().min(1),
  title: z.string().min(1),
  path: z.string().default(""),
});

export const skillAttachmentSchema = z.object({
  skillId: z.string().min(1),
  title: z.string().default(""),
  description: z.string().default(""),
  storagePath: z.string().min(1),
});

export const employeeAttachmentSchema = z.object({
  employeeId: z.string().min(1),
  name: z.string().default(""),
  role: z.string().default(""),
  promptTemplate: z.string().default(""),
  defaultSkills: z.array(skillAttachmentSchema).default([]),
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
  structuredFields: z.array(z.object({
    name: z.string().default(""),
    description: z.string().default(""),
  })).default([]),
  firstChoice: z.string().default(""),
  secondChoice: z.string().default(""),
  attachments: z.array(nodeAttachmentSchema).default([]),
  knowledgeAttachments: z.array(knowledgeAttachmentSchema).default([]),
  skillAttachments: z.array(skillAttachmentSchema).default([]),
  employee: employeeAttachmentSchema.optional(),
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
  referenceName: z.string().default(""),
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
  skillAttachments: z.array(skillAttachmentSchema).default([]),
  employee: employeeAttachmentSchema.optional(),
});

export const humanApprovalNodeConfigSchema = z.object({
  primitive: z.literal("humanApproval").default("humanApproval"),
  instruction: z.string().default("Prüfe das Ergebnis und gib es frei."),
});

export const dialogInputFieldTypeSchema = z.enum([
  "string",
  "number",
  "integer",
  "decimal",
  "selection",
  "boolean",
  "radio",
]);

export const dialogInputFieldSchema = z.object({
  name: z.string().default(""),
  type: dialogInputFieldTypeSchema.default("string"),
  options: z.array(z.string()).default([]),
});

export const dialogInputDefinitionSchema = z.object({
  instruction: z.string().default("Bitte fülle das Formular aus."),
  fields: z.array(dialogInputFieldSchema).default([]),
});

export const dialogInputNodeConfigSchema = dialogInputDefinitionSchema.extend({
  primitive: z.literal("dialogInput").default("dialogInput"),
});

export const mediaInputDefinitionSchema = z.object({
  instruction: z.string().default("Bitte füge ein Bild hinzu."),
});

export const mediaInputNodeConfigSchema = mediaInputDefinitionSchema.extend({
  primitive: z.literal("mediaInput").default("mediaInput"),
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

export const readChannelEventNodeConfigSchema = z.object({
  primitive: z.literal("readChannelEvent").default("readChannelEvent"),
  kind: z.enum(["email", "whatsapp", "sms"]).default("whatsapp"),
});

export const sendChannelMessageNodeConfigSchema = z.object({
  primitive: z.literal("sendChannelMessage").default("sendChannelMessage"),
  kind: z.enum(["email", "whatsapp", "sms"]).default("whatsapp"),
  connectorId: z.string().optional(),
  recipient: z.string().default(""),
  subject: z.string().default(""),
  message: z.string().default(""),
});

export const nodeConfigSchema = z.discriminatedUnion("primitive", [
  stringInputNodeConfigSchema,
  scriptNodeConfigSchema,
  promptNodeConfigSchema,
  conditionalNodeConfigSchema,
  iterativeRefinementNodeConfigSchema,
  humanApprovalNodeConfigSchema,
  dialogInputNodeConfigSchema,
  mediaInputNodeConfigSchema,
  writeFileNodeConfigSchema,
  readFileNodeConfigSchema,
  readEmailNodeConfigSchema,
  readChannelEventNodeConfigSchema,
  sendChannelMessageNodeConfigSchema,
]);

export const workflowNodeSchema = z.object({
  id: z.string().min(1),
  primitive: workflowPrimitiveSchema,
  title: z.string().min(1),
  description: z.string().default(""),
  referenceName: z.string().default(""),
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

const fileReferenceSchema = z.object({
  fileId: z.string().min(1),
  versionId: z.string().min(1),
  displayName: z.string().min(1),
  contentType: z.string().min(1),
  sizeBytes: z.number().nonnegative(),
});

const jsonValueSchema = z.union([
  z.string(),
  z.number(),
  z.boolean(),
  z.null(),
  z.array(z.unknown()),
  z.record(z.string(), z.unknown()),
]);

export const nodeOutputValueSchema: z.ZodType<NodeOutputValue> =
  z.discriminatedUnion("type", [
    z.object({type: z.literal("string"), value: z.string()}),
    z.object({type: z.literal("datetime"), value: z.string()}),
    z.object({type: z.literal("number"), value: z.number()}),
    z.object({type: z.literal("boolean"), value: z.boolean()}),
    z.object({type: z.literal("json"), value: jsonValueSchema}),
    z.object({type: z.literal("file"), value: fileReferenceSchema}),
    z.object({type: z.literal("media"), value: fileReferenceSchema}),
  ]);

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
  interaction: z.discriminatedUnion("kind", [
    z.object({
      kind: z.literal("approval"),
      instruction: z.string(),
    }),
    dialogInputDefinitionSchema.extend({kind: z.literal("dialogInput")}),
    mediaInputDefinitionSchema.extend({kind: z.literal("mediaInput")}),
  ]).optional(),
  dialogInput: dialogInputDefinitionSchema.optional(),
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
  formValues: z.record(z.string(), z.unknown()).default({}),
});

export const reviewTaskRunOutputSchema = z.object({
  runId: z.string().min(1),
  status: z.enum(["queued", "rejected"]),
});

export type {
  CompletedTaskGraphOutput,
  EmployeeAttachment,
  KnowledgeAttachment,
  NodeAttachment,
  NodeExecutionResult,
  NodeOutputValue,
  SkillAttachment,
  TaskDefinition,
  TaskGraphInput,
  TaskGraphOutput,
  TaskResumeState,
  WaitingTaskGraphOutput,
  WorkflowEdge,
  WorkflowNode,
} from "../../../domain/entities/task.js";

export type RunTaskDefinitionInput = z.infer<
  typeof runTaskDefinitionInputSchema
>;
export type RunTaskDefinitionOutput = z.infer<
  typeof runTaskDefinitionOutputSchema
>;
export type ReviewTaskRunInput = z.infer<typeof reviewTaskRunInputSchema>;
export type ReviewTaskRunOutput = z.infer<typeof reviewTaskRunOutputSchema>;
