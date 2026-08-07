import {
  type EmployeeAttachment,
  type KnowledgeAttachment,
  type NodeAttachment,
  type SkillAttachment,
} from "./attachments.js";
export type {
  EmployeeAttachment,
  KnowledgeAttachment,
  NodeAttachment,
  SkillAttachment,
} from "./attachments.js";
export type WorkflowPrimitive =
  | "stringInput"
  | "script"
  | "prompt"
  | "conditionalFlow"
  | "iterativeRefinement"
  | "writeFile"
  | "readFile"
  | "readEmail"
  | "readChannelEvent"
  | "sendChannelMessage"
  | "toolCall"
  | "humanApproval"
  | "validation";
export type PromptOutputType = "text" | "decision" | "structured";
export type ChannelMessageKind = "email" | "whatsapp" | "sms";
export type StructuredOutputField = {
  name: string;
  description: string;
};
export type StringInputNodeConfig = {
  primitive: "stringInput";
  value: string;
};
export type ScriptNodeConfig = {
  primitive: "script";
  script: string;
  attachments: NodeAttachment[];
};
export type PromptNodeConfig = {
  primitive: "prompt";
  instruction: string;
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
  referenceName: string;
  config?: unknown;
};
export type BranchWorkflowGraph = {
  nodes: BranchWorkflowNode[];
  edges: WorkflowEdge[];
};
export type ConditionalBranch = {
  id: string;
  label: string;
  nodeIds: string[];
  graph: BranchWorkflowGraph;
};
export type ConditionalNodeConfig = {
  primitive: "conditionalFlow";
  choices: string[];
  branches: ConditionalBranch[];
};
export type IterativeRefinementNodeConfig = {
  primitive: "iterativeRefinement";
  optimizerPrompt: string;
  critiquePrompt: string;
  maxIterations: number;
  skillAttachments: SkillAttachment[];
  employee?: EmployeeAttachment;
};
export type HumanApprovalNodeConfig = {
  primitive: "humanApproval";
  instruction: string;
};
export type WriteFileNodeConfig = {
  primitive: "writeFile";
  fileName: string;
  contentType: string;
  fileId?: string;
};
export type ReadFileNodeConfig = {
  primitive: "readFile";
  file?: NodeAttachment;
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
export type NodeConfig =
  | StringInputNodeConfig
  | ScriptNodeConfig
  | PromptNodeConfig
  | ConditionalNodeConfig
  | IterativeRefinementNodeConfig
  | HumanApprovalNodeConfig
  | WriteFileNodeConfig
  | ReadFileNodeConfig
  | ReadEmailNodeConfig
  | ReadChannelEventNodeConfig
  | SendChannelMessageNodeConfig;
export type WorkflowNode = {
  id: string;
  primitive: WorkflowPrimitive;
  title: string;
  description: string;
  referenceName: string;
  config: NodeConfig;
};
export type TaskDefinition = {
  id: string;
  title: string;
  objective: string;
  nodes: WorkflowNode[];
  edges: WorkflowEdge[];
};
export type NodeOutputValue = {
  type: "string" | "datetime" | "number" | "boolean" | "json";
  value?: unknown;
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
