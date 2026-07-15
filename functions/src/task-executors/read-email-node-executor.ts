import {
  datetimeOutput,
  executedNode,
  stringOutput,
  textOutputs,
  type NodeExecutor,
} from "../task-runner/node-executor.js";

export const readEmailNodeExecutor: NodeExecutor = {
  primitive: "readEmail",
  async execute(input, runContext) {
    const event = emailEventFrom(runContext.input);
    return executedNode(input.node, {
      ...textOutputs(event.message),
      sender: stringOutput(event.senderEmail),
      subject: stringOutput(event.subject),
      message: stringOutput(event.message),
      receivedAt: datetimeOutput(event.receivedAt),
    });
  },
};

type EmailEvent = {
  type: "emailReceived";
  senderEmail: string;
  subject: string;
  message: string;
  receivedAt: string;
};

function emailEventFrom(input: Record<string, unknown>): EmailEvent {
  const event = input.event;
  if (!isRecord(event) || event.type !== "emailReceived") {
    throw new Error("E-Mail lesen: Dieser TaskRun wurde nicht durch eine E-Mail gestartet.");
  }
  return {
    type: "emailReceived",
    senderEmail: stringField(event, "senderEmail"),
    subject: stringField(event, "subject"),
    message: stringField(event, "message"),
    receivedAt: stringField(event, "receivedAt"),
  };
}

function stringField(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  return typeof value === "string" ? value : "";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}
