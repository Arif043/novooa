import {z} from "genkit";
import {documentFilterOperators} from "../../../../data/domain/entities/document-filter.js";
import {
  type BranchCondition,
  type NodeOutputValue,
  workflowPrimitives,
} from "../../../domain/entities/task.js";
import {
  modelInputSourceTypes,
  modelTensorDataTypes,
} from "../../../../machine_learning/domain/entities/model-contract.js";

export const workflowPrimitiveSchema = z.enum(workflowPrimitives);

export const promptOutputTypeSchema = z.enum([
  "text",
  "decision",
  "structured",
  "image",
]);

export const structuredOutputFieldTypeSchema = z.enum([
  "string",
  "number",
  "boolean",
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
  inputTemplate: z.string().default(""),
  attachments: z.array(nodeAttachmentSchema).default([]),
});

export const promptNodeConfigSchema = z.object({
  primitive: z.literal("prompt").default("prompt"),
  instruction: z.string().default(""),
  languageModelId: z.string().optional(),
  outputType: promptOutputTypeSchema.default("text"),
  choices: z.array(z.string()).default([]),
  structuredFields: z.array(z.object({
    name: z.string().default(""),
    description: z.string().default(""),
    type: structuredOutputFieldTypeSchema.default("string"),
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
  outputName: z.string().default(""),
  config: z.unknown().optional(),
});

const branchWorkflowGraphSchema = z.object({
  nodes: z.array(branchWorkflowNodeSchema).default([]),
  edges: z.array(workflowEdgeSchema).default([]),
});

export const comparisonOperatorSchema = z.enum([
  "equals",
  "notEquals",
  "greaterThan",
  "greaterThanOrEqual",
  "lessThan",
  "lessThanOrEqual",
  "contains",
]);

export const booleanCombinatorSchema = z.enum(["and", "or", "xor"]);

// Selbstreferenzierend (eine Gruppe enthält weitere Bedingungen) — `z.lazy`
// ist Zods Standardmuster dafür, da die Schema-Definition sonst sich selbst
// referenzieren müsste, bevor sie existiert.
export const branchConditionSchema: z.ZodType<BranchCondition> = z.lazy(() =>
  z.discriminatedUnion("kind", [
    z.object({
      kind: z.literal("comparison"),
      left: z.string(),
      operator: comparisonOperatorSchema,
      right: z.string(),
    }),
    z.object({
      kind: z.literal("group"),
      combinator: booleanCombinatorSchema,
      children: z.array(branchConditionSchema),
    }),
  ]),
);

export const conditionalBranchSchema = z.object({
  id: z.string().min(1),
  label: z.string().default(""),
  nodeIds: z.array(z.string().min(1)).default([]),
  graph: branchWorkflowGraphSchema.default({nodes: [], edges: []}),
  condition: branchConditionSchema.optional(),
});

export const conditionalNodeConfigSchema = z.object({
  primitive: z.literal("conditionalFlow").default("conditionalFlow"),
  valueTemplate: z.string().default(""),
  choices: z.array(z.string()).default([]),
  branches: z.array(conditionalBranchSchema).default([]),
});

export const iterativeRefinementNodeConfigSchema = z.object({
  primitive: z.literal("iterativeRefinement").default("iterativeRefinement"),
  draftTemplate: z.string().default(""),
  optimizerPrompt: z.string().default(""),
  critiquePrompt: z.string().default(""),
  maxIterations: z.number().int().min(1).max(5).default(2),
  skillAttachments: z.array(skillAttachmentSchema).default([]),
  employee: employeeAttachmentSchema.optional(),
});

export const humanApprovalNodeConfigSchema = z.object({
  primitive: z.literal("humanApproval").default("humanApproval"),
  instruction: z.string().default("Prüfe das Ergebnis und gib es frei."),
  reviewTemplate: z.string().default(""),
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
  documentScanEnabled: z.boolean().default(false),
});

export const mediaInputNodeConfigSchema = mediaInputDefinitionSchema.extend({
  primitive: z.literal("mediaInput").default("mediaInput"),
});

export const modelInferenceNodeConfigSchema = z.object({
  primitive: z.literal("modelInference").default("modelInference"),
  modelId: z.string().default(""),
  inputMappings: z.array(z.object({
    modelInputName: z.string(),
    workflowMapping: z.string().default(""),
    sourceType: z.enum(modelInputSourceTypes).default("text"),
    dataType: z.enum(modelTensorDataTypes).default("float32"),
    shape: z.array(z.union([z.number().int().positive(), z.literal("dynamic")])).default([1]),
  })).default([]),
  outputParameters: z.array(z.object({
    outputName: z.string().min(1),
    name: z.string().min(1),
    value: z.number().int(),
  })).default([]),
  settings: z.array(z.object({
    name: z.string().min(1),
    valueTemplate: z.string(),
  })).default([]),
});

export const textToSpeechNodeConfigSchema = modelInferenceNodeConfigSchema.extend({
  primitive: z.literal("textToSpeech").default("textToSpeech"),
});

export const speechToTextNodeConfigSchema = modelInferenceNodeConfigSchema.extend({
  primitive: z.literal("speechToText").default("speechToText"),
});

export const forEachNodeConfigSchema = z.object({
  primitive: z.literal("forEach").default("forEach"),
  itemsTemplate: z.string().default(""),
  itemsPointer: z.string().default(""),
  graph: branchWorkflowGraphSchema.default({nodes: [], edges: []}),
});

export const writeFileNodeConfigSchema = z.object({
  primitive: z.literal("writeFile").default("writeFile"),
  contentTemplate: z.string().default(""),
  fileName: z.string().max(240).default(""),
  contentType: z.string().max(120).default(""),
  fileId: z.string().optional(),
  folderId: z.string().optional(),
});

export const readFileNodeConfigSchema = z.object({
  primitive: z.literal("readFile").default("readFile"),
  file: nodeAttachmentSchema.optional(),
});

export const documentLookupNodeConfigSchema = z.object({
  primitive: z.literal("documentLookup").default("documentLookup"),
  collectionName: z.string().default(""),
  filters: z.array(z.object({
    field: z.string().default(""),
    operator: z.enum(documentFilterOperators).default("equals"),
    value: z.string().default(""),
  })).default([]),
});

export const saveDocumentNodeConfigSchema = z.object({
  primitive: z.literal("saveDocument").default("saveDocument"),
  collectionName: z.string().default(""),
  filters: z.array(z.object({
    field: z.string().default(""),
    operator: z.enum(documentFilterOperators).default("equals"),
    value: z.string().default(""),
  })).default([]),
  fields: z.array(z.object({
    field: z.string().default(""),
    value: z.string().default(""),
  })).default([]),
});

export const tableFromCollectionNodeConfigSchema = z.object({
  primitive: z.literal("tableFromCollection").default("tableFromCollection"),
  collectionName: z.string().default(""),
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

export const notificationSendNodeConfigSchema = z.object({
  primitive: z.literal("notificationSend").default("notificationSend"),
  title: z.string().optional(),
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
  modelInferenceNodeConfigSchema,
  textToSpeechNodeConfigSchema,
  speechToTextNodeConfigSchema,
  forEachNodeConfigSchema,
  writeFileNodeConfigSchema,
  readFileNodeConfigSchema,
  documentLookupNodeConfigSchema,
  saveDocumentNodeConfigSchema,
  tableFromCollectionNodeConfigSchema,
  readEmailNodeConfigSchema,
  readChannelEventNodeConfigSchema,
  sendChannelMessageNodeConfigSchema,
  notificationSendNodeConfigSchema,
]);

export const workflowNodeSchema = z.object({
  id: z.string().min(1),
  primitive: workflowPrimitiveSchema,
  title: z.string().min(1),
  description: z.string().default(""),
  outputName: z.string().default(""),
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

// Spiegelt `WorkflowTable` (workflow-value.ts) — schemalos, da
// Datensammlungen selbst schemalos sind (siehe dortiger Kommentar).
const workflowTableValueSchema = z.object({
  columns: z.array(z.string()),
  rows: z.array(z.array(z.unknown())),
});

export const nodeOutputValueSchema: z.ZodType<NodeOutputValue> =
  z.discriminatedUnion("type", [
    z.object({type: z.literal("string"), value: z.string()}),
    z.object({type: z.literal("datetime"), value: z.string()}),
    z.object({type: z.literal("number"), value: z.number()}),
    z.object({type: z.literal("boolean"), value: z.boolean()}),
    z.object({type: z.literal("json"), value: jsonValueSchema}),
    z.object({type: z.literal("file"), value: fileReferenceSchema}),
    z.object({type: z.literal("media"), value: fileReferenceSchema}),
    z.object({type: z.literal("audio"), value: fileReferenceSchema}),
    z.object({type: z.literal("table"), value: workflowTableValueSchema}),
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
  WorkflowGraph,
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
