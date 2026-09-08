import {
  type ReviewTaskWorkflowInput,
  type StartTaskWorkflowInput,
  type TaskWorkflow,
} from "../../domain/usecases/task-workflow.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";

export class LocalTaskRunHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly taskWorkflow: TaskWorkflow,
    private readonly userId: string,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.method !== "POST") return null;
    if (request.url === "/v1/task-runs") return this.start(request.body);
    if (request.url === "/v1/task-runs/review") return this.review(request.body);
    return null;
  }

  private async start(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const output = await this.taskWorkflow.start(startInputFrom(body), {uid: this.userId});
      return {body: output, statusCode: 202};
    } catch (error) {
      return inputErrorResponse(error);
    }
  }

  private async review(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const output = await this.taskWorkflow.review(reviewInputFrom(body), {uid: this.userId});
      return {body: output, statusCode: 200};
    } catch (error) {
      return inputErrorResponse(error);
    }
  }
}

class LocalTaskRunHttpInputError extends Error {}

function startInputFrom(value: unknown): StartTaskWorkflowInput {
  const input = recordFrom(value, "Die Aufgabenausführung erwartet ein Objekt.");
  return {taskId: requiredString(input.taskId, "taskId"), context: optionalString(input.context)};
}

function reviewInputFrom(value: unknown): ReviewTaskWorkflowInput {
  const input = recordFrom(value, "Die Run-Prüfung erwartet ein Objekt.");
  if (input.decision !== "approve" && input.decision !== "reject") {
    throw new LocalTaskRunHttpInputError("decision muss approve oder reject sein.");
  }
  return {
    runId: requiredString(input.runId, "runId"),
    decision: input.decision,
    output: optionalString(input.output),
    formValues: recordFrom(input.formValues ?? {}, "formValues muss ein Objekt sein."),
  };
}

function inputErrorResponse(error: unknown): LocalRuntimeResponse {
  if (error instanceof LocalTaskRunHttpInputError) {
    return {body: {error: error.message}, statusCode: 400};
  }
  throw error;
}

function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw new LocalTaskRunHttpInputError(message);
}

function requiredString(value: unknown, name: string): string {
  if (typeof value === "string" && value.trim().length > 0) return value;
  throw new LocalTaskRunHttpInputError(`${name} muss ein nicht leerer String sein.`);
}

function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}
