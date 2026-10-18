import {nodeFailures} from "../entities/node-failures.js";
import {err, ok} from "neverthrow";
import {type NodeOutputValue} from "../entities/workflow-value.js";
import {datetimeOutput, executedNode, stringOutput, type NodeExecutor} from "./node-executor.js";

/** Macht das Ereignis, das den Lauf über einen Webhook gestartet hat, als Werte für die weiteren Bausteine nutzbar. */
export const readWebhookNodeExecutor: NodeExecutor = {
  primitive: "readWebhook",
  async execute(node, runContext) {
    const event = webhookEventFrom(runContext.input);
    if (event === undefined) return err(nodeFailures.triggerMismatch("webhook"));
    const body = event.body;
    const outputs: Record<string, NodeOutputValue> = {
      value: typeof body === "string" ? stringOutput(body) : {type: "json", value: body},
      method: stringOutput(stringField(event, "method")),
      query: {type: "json", value: objectField(event, "query")},
      headers: {type: "json", value: objectField(event, "headers")},
      receivedAt: datetimeOutput(stringField(event, "receivedAt")),
    };
    return ok(executedNode(node, outputs));
  },
};

function webhookEventFrom(input: Record<string, unknown>): Record<string, unknown> | undefined {
  const event = input.event;
  return isRecord(event) && event.type === "webhookReceived" ? event : undefined;
}

function stringField(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  return typeof value === "string" ? value : "";
}

function objectField(data: Record<string, unknown>, key: string): Record<string, unknown> {
  const value = data[key];
  return isRecord(value) ? value : {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
