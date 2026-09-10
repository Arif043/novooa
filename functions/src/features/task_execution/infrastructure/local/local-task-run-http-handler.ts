import {
  type ReviewTaskWorkflowInput,
  type StartTaskWorkflowInput,
  type TaskWorkflow,
} from "../../domain/usecases/task-workflow.js";
import {TaskRunFailure} from "../../domain/entities/task-run-failure.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type ApplicationLogger} from "../../../../shared/logging/application-logger.js";

export class LocalTaskRunHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly taskWorkflow: TaskWorkflow,
    private readonly userId: string,
    private readonly logger: ApplicationLogger,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.method !== "POST") return null;
    if (request.url === "/v1/task-runs") return this.start(request.body);
    if (request.url === "/v1/task-runs/review") return this.review(request.body);
    return null;
  }

  private async start(body: unknown): Promise<LocalRuntimeResponse> {
    const inputOrFailure = startInputFrom(body);
    if (inputOrFailure instanceof TaskRunFailure) return failureResponse(inputOrFailure);
    try {
      const output = await this.taskWorkflow.start(inputOrFailure, {uid: this.userId});
      return {body: output, statusCode: 202};
    } catch (error) {
      return this.unexpectedFailure("start_failed", error);
    }
  }

  private async review(body: unknown): Promise<LocalRuntimeResponse> {
    const inputOrFailure = reviewInputFrom(body);
    if (inputOrFailure instanceof TaskRunFailure) return failureResponse(inputOrFailure);
    try {
      const output = await this.taskWorkflow.review(inputOrFailure, {uid: this.userId});
      return {body: output, statusCode: 200};
    } catch (error) {
      return this.unexpectedFailure("review_failed", error);
    }
  }

  private unexpectedFailure(event: string, error: unknown): LocalRuntimeResponse {
    this.logger.exception(`local_task_run_http_handler.${event}`, error, {userId: this.userId});
    return {
      body: {error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."},
      statusCode: 500,
    };
  }
}

function startInputFrom(value: unknown): StartTaskWorkflowInput | TaskRunFailure {
  const input = recordFrom(value, "invalidRequest", "Die Aufgabenausführung erwartet ein Objekt.");
  if (input instanceof TaskRunFailure) return input;
  const taskId = requiredString(input.taskId, "taskId", "invalidTaskId");
  if (taskId instanceof TaskRunFailure) return taskId;
  return {
    taskId,
    context: optionalString(input.context),
  };
}

function reviewInputFrom(value: unknown): ReviewTaskWorkflowInput | TaskRunFailure {
  const input = recordFrom(value, "invalidRequest", "Die Run-Prüfung erwartet ein Objekt.");
  if (input instanceof TaskRunFailure) return input;
  if (input.decision !== "approve" && input.decision !== "reject") {
    return failure("invalidReviewDecision", "decision muss approve oder reject sein.");
  }
  const runId = requiredString(input.runId, "runId", "invalidRequest");
  if (runId instanceof TaskRunFailure) return runId;
  const formValues = recordFrom(
    input.formValues ?? {},
    "invalidFormValues",
    "formValues muss ein Objekt sein.",
  );
  if (formValues instanceof TaskRunFailure) return formValues;
  return {
    runId,
    decision: input.decision,
    output: optionalString(input.output),
    formValues,
  };
}

function failureResponse(failure: TaskRunFailure): LocalRuntimeResponse {
  return {body: {failure: {code: failure.code, message: failure.message}}, statusCode: 400};
}

function recordFrom(
  value: unknown,
  code: TaskRunFailure["code"],
  message: string,
): Record<string, unknown> | TaskRunFailure {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return failure(code, message);
}

function requiredString(
  value: unknown,
  name: string,
  code: TaskRunFailure["code"],
): string | TaskRunFailure {
  if (typeof value === "string" && value.trim().length > 0) return value;
  return failure(code, `${name} muss ein nicht leerer String sein.`);
}

function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function failure(code: TaskRunFailure["code"], message: string): TaskRunFailure {
  return new TaskRunFailure(code, message);
}
