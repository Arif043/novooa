import {
  type EmployeeAttachment,
  type KnowledgeAttachment,
  type NodeAttachment,
  type SkillAttachment,
} from "./attachments.js";
import {
  type DialogInputDefinition,
} from "./dialog-input.js";
import {
  type MediaInputDefinition,
} from "./media-input.js";
import {
  type TaskRunInteraction,
} from "./task-run-interaction.js";
import {
  type ModelInputSourceType,
  type ModelTensorDataType,
  type TensorDimension,
} from "../../../machine_learning/domain/entities/model-contract.js";
import {type NodeOutputValue} from "./workflow-value.js";
export type {
  DialogInputDefinition,
  DialogInputField,
  DialogInputFieldType,
  DialogInputValue,
} from "./dialog-input.js";
export type {
  MediaInputDefinition,
  MediaInputFileReference,
} from "./media-input.js";
export type {TaskRunInteraction} from "./task-run-interaction.js";
export type {
  EmployeeAttachment,
  KnowledgeAttachment,
  NodeAttachment,
  SkillAttachment,
} from "./attachments.js";
export type {
  FileReference,
  MediaReference,
  NodeOutputValue,
} from "./workflow-value.js";
export const workflowPrimitives = [
  "stringInput",
  "script",
  "prompt",
  "conditionalFlow",
  "iterativeRefinement",
  "writeFile",
  "readFile",
  "readEmail",
  "readChannelEvent",
  "sendChannelMessage",
  "notificationSend",
  "toolCall",
  "humanApproval",
  "dialogInput",
  "mediaInput",
  "modelInference",
  "forEach",
  "documentLookup",
  "saveDocument",
  "tableFromCollection",
  "validation",
] as const;

export type WorkflowPrimitive = (typeof workflowPrimitives)[number];
export type PromptOutputType = "text" | "decision" | "structured" | "image";
export type ChannelMessageKind = "email" | "whatsapp" | "sms";
export type StructuredOutputFieldType = "string" | "number" | "boolean";
export type StructuredOutputField = {
  name: string;
  description: string;
  type: StructuredOutputFieldType;
};
export type StringInputNodeConfig = {
  primitive: "stringInput";
  value: string;
};
export type ScriptNodeConfig = {
  primitive: "script";
  script: string;
  inputTemplate?: string;
  attachments: NodeAttachment[];
};
export type PromptNodeConfig = {
  primitive: "prompt";
  instruction: string;
  languageModelId?: string;
  outputType: PromptOutputType;
  choices: string[];
  structuredFields: StructuredOutputField[];
  firstChoice: string;
  secondChoice: string;
  attachments: NodeAttachment[];
  knowledgeAttachments: KnowledgeAttachment[];
  skillAttachments: SkillAttachment[];
  employee?: EmployeeAttachment;
};
export type WorkflowEdge = {
  from: string;
  to: string;
  conditionLabel?: string;
};
export type BranchWorkflowNode = {
  id: string;
  primitive: WorkflowPrimitive;
  title: string;
  description: string;
  outputName: string;
  config?: unknown;
};
export type BranchWorkflowGraph = {
  nodes: BranchWorkflowNode[];
  edges: WorkflowEdge[];
};
export type ComparisonOperator =
  | "equals"
  | "notEquals"
  | "greaterThan"
  | "greaterThanOrEqual"
  | "lessThan"
  | "lessThanOrEqual"
  | "contains";
export type BooleanCombinator = "and" | "or" | "xor";
export type BranchCondition =
  | {kind: "comparison"; left: string; operator: ComparisonOperator; right: string}
  | {kind: "group"; combinator: BooleanCombinator; children: BranchCondition[]};
export type ConditionalBranch = {
  id: string;
  label: string;
  nodeIds: string[];
  graph: BranchWorkflowGraph;
  /** `undefined` = kein eigener Ausdruck — entweder der "Sonst"-Zweig oder
   * ein Alt-/Entscheidungs-Prompt-getriebener Zweig aus dem bisherigen
   * Label-Matching-Pfad (`conditional-executor.ts`). Trägt irgendein Zweig
   * dieses Knotens ein `condition`, wertet `conditional-node-executor.ts`
   * ausschließlich über `selectConditionedBranch` aus. */
  condition?: BranchCondition;
};
export type ConditionalNodeConfig = {
  primitive: "conditionalFlow";
  valueTemplate?: string;
  choices: string[];
  branches: ConditionalBranch[];
};
export type IterativeRefinementNodeConfig = {
  primitive: "iterativeRefinement";
  draftTemplate?: string;
  optimizerPrompt: string;
  critiquePrompt: string;
  maxIterations: number;
  skillAttachments: SkillAttachment[];
  employee?: EmployeeAttachment;
};
export type HumanApprovalNodeConfig = {
  primitive: "humanApproval";
  instruction: string;
  reviewTemplate?: string;
};
export type DialogInputNodeConfig = DialogInputDefinition & {
  primitive: "dialogInput";
};
export type MediaInputNodeConfig = MediaInputDefinition & {
  primitive: "mediaInput";
};
export type ModelInferenceNodeConfig = {
  primitive: "modelInference";
  modelId: string;
  inputMappings: ModelInferenceInputMapping[];
  outputParameters: ModelInferenceOutputParameter[];
};
export type ModelInferenceInputMapping = {
  modelInputName: string;
  workflowMapping: string;
  sourceType: ModelInputSourceType;
  dataType: ModelTensorDataType;
  shape: readonly TensorDimension[];
};
export type ModelInferenceOutputParameter = {
  outputName: string;
  name: string;
  value: number;
};
export type ForEachNodeConfig = {
  primitive: "forEach";
  itemsTemplate?: string;
  itemsPointer: string;
  graph: BranchWorkflowGraph;
};
export type WriteFileNodeConfig = {
  primitive: "writeFile";
  contentTemplate?: string;
  fileName: string;
  contentType: string;
  fileId?: string;
};
export type ReadFileNodeConfig = {
  primitive: "readFile";
  file?: NodeAttachment;
};
export type DocumentLookupFilterConfig = {
  field: string;
  operator: import("../../../data/domain/entities/document-filter.js").DocumentFilterOperator;
  value: string;
};

export type DocumentLookupNodeConfig = {
  primitive: "documentLookup";
  collectionName: string;
  filters: DocumentLookupFilterConfig[];
};

export type DocumentFieldAssignment = {
  field: string;
  value: string;
};

export type SaveDocumentNodeConfig = {
  primitive: "saveDocument";
  collectionName: string;
  filters: DocumentLookupFilterConfig[];
  fields: DocumentFieldAssignment[];
};
export type TableFromCollectionNodeConfig = {
  primitive: "tableFromCollection";
  collectionName: string;
};
export type ReadEmailNodeConfig = {
  primitive: "readEmail";
};
export type ReadChannelEventNodeConfig = {
  primitive: "readChannelEvent";
  kind: ChannelMessageKind;
};
export type SendChannelMessageNodeConfig = {
  primitive: "sendChannelMessage";
  kind: ChannelMessageKind;
  connectorId?: string;
  recipient: string;
  subject?: string;
  message: string;
};
export type NotificationSendNodeConfig = {
  primitive: "notificationSend";
  title?: string;
  message: string;
};
export type NodeConfig =
  | StringInputNodeConfig
  | ScriptNodeConfig
  | PromptNodeConfig
  | ConditionalNodeConfig
  | IterativeRefinementNodeConfig
  | HumanApprovalNodeConfig
  | DialogInputNodeConfig
  | MediaInputNodeConfig
  | ModelInferenceNodeConfig
  | ForEachNodeConfig
  | WriteFileNodeConfig
  | ReadFileNodeConfig
  | DocumentLookupNodeConfig
  | SaveDocumentNodeConfig
  | TableFromCollectionNodeConfig
  | ReadEmailNodeConfig
  | ReadChannelEventNodeConfig
  | SendChannelMessageNodeConfig
  | NotificationSendNodeConfig;
export type WorkflowNode = {
  id: string;
  primitive: WorkflowPrimitive;
  title: string;
  description: string;
  outputName: string;
  config: NodeConfig;
};
export type WorkflowGraph = {
  nodes: WorkflowNode[];
  edges: WorkflowEdge[];
};

export type TaskDefinition = WorkflowGraph & {
  id: string;
  title: string;
  objective: string;
};
export type NodeExecutionResult = {
  nodeId: string;
  primitive: WorkflowPrimitive;
  status: "executed" | "skipped" | "waitingForApproval";
  outputs: Record<string, NodeOutputValue>;
  variables?: Record<string, unknown>;
  selectedNodeId?: string | null;
  selectedBranchId?: string | null;
  selectedBranchLabel?: string | null;
  message?: string;
  interaction?: TaskRunInteraction;
  dialogInput?: DialogInputDefinition;
};
export type TaskResumeState = {
  nodeResults: NodeExecutionResult[];
  variables: Record<string, unknown>;
  remainingNodeIds: string[];
  skippedNodeIds: string[];
  waitingNodeId?: string;
};
export type TaskGraphInput = {
  taskDefinition: TaskDefinition;
  context: string;
  teamId: string;
  input?: Record<string, unknown>;
};
export type CompletedTaskGraphOutput = {
  status: "completed";
  taskId: string;
  finalOutput: string;
  nodeResults: NodeExecutionResult[];
};
export type WaitingTaskGraphOutput = {
  status: "waitingForApproval";
  taskId: string;
  finalOutput: string;
  nodeResults: NodeExecutionResult[];
  resumeState: TaskResumeState;
};
export type TaskGraphOutput = CompletedTaskGraphOutput | WaitingTaskGraphOutput;
