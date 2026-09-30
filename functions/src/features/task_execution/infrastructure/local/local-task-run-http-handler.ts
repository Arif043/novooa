import { type FastifyInstance, type FastifyReply } from "fastify";
import { type ReviewTaskWorkflowInput, type StartTaskWorkflowInput, type TaskWorkflow, } from "../../domain/usecases/task-workflow.js";
import { TaskRunFailure } from "../../domain/entities/task-run-failure.js";
import { type ApplicationLogger } from "../../../../shared/logging/application-logger.js";
import { type LocalRuntimeRealtimeNotifier } from "../../../../shared/local/local-runtime-realtime-notifier.js";
export class LocalTaskRunHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalTaskRunHttpHandler): void {
    http.post("/v1/task-runs", (request, reply) => current().start(request.body, reply));
    http.post("/v1/task-runs/review", (request, reply) => current().review(request.body, reply));
  }
  constructor(private readonly taskWorkflow: TaskWorkflow, private readonly userId: string, private readonly logger: ApplicationLogger, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async start(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    const inputOrFailure = startInputFrom(body);
    if (inputOrFailure instanceof TaskRunFailure)
      return failureResponse(inputOrFailure, reply);
    try {
      const output = await this.taskWorkflow.start(inputOrFailure, { uid: this.userId });
      this.publishRunChanges();
      return reply.code(202).send(output);
    }
    catch (error) {
      return this.unexpectedFailure("start_failed", error, reply);
    }
  }
  private async review(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
    const inputOrFailure = reviewInputFrom(body);
    if (inputOrFailure instanceof TaskRunFailure)
      return failureResponse(inputOrFailure, reply);
    try {
      const output = await this.taskWorkflow.review(inputOrFailure, { uid: this.userId });
      this.publishRunChanges();
      return reply.code(200).send(output);
    }
    catch (error) {
      return this.unexpectedFailure("review_failed", error, reply);
    }
  }
  /** Ein Run ändert seinen Status nie ohne eine begleitende Aktivität. */
  private publishRunChanges(): void {
    this.notifier.publish("task-runs");
    this.notifier.publish("task-activities");
  }
  private unexpectedFailure(event: string, error: unknown, reply: FastifyReply): FastifyReply {
    this.logger.exception(`local_task_run_http_handler.${event}`, error, { userId: this.userId });
    return reply.code(500).send({ error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten." });
  }
}
function startInputFrom(value: unknown): StartTaskWorkflowInput | TaskRunFailure {
  const input = recordFrom(value, "invalidRequest", "Die Aufgabenausführung erwartet ein Objekt.");
  if (input instanceof TaskRunFailure)
    return input;
  const taskId = requiredString(input.taskId, "taskId", "invalidTaskId");
  if (taskId instanceof TaskRunFailure)
    return taskId;
  return {
    taskId,
    context: optionalString(input.context),
  };
}
function reviewInputFrom(value: unknown): ReviewTaskWorkflowInput | TaskRunFailure {
  const input = recordFrom(value, "invalidRequest", "Die Run-Prüfung erwartet ein Objekt.");
  if (input instanceof TaskRunFailure)
    return input;
  if (input.decision !== "approve" && input.decision !== "reject") {
    return failure("invalidReviewDecision", "decision muss approve oder reject sein.");
  }
  const runId = requiredString(input.runId, "runId", "invalidRequest");
  if (runId instanceof TaskRunFailure)
    return runId;
  const formValues = recordFrom(input.formValues ?? {}, "invalidFormValues", "formValues muss ein Objekt sein.");
  if (formValues instanceof TaskRunFailure)
    return formValues;
  return {
    runId,
    decision: input.decision,
    output: optionalString(input.output),
    formValues,
  };
}
function failureResponse(failure: TaskRunFailure, reply: FastifyReply): FastifyReply {
  return reply.code(400).send({ failure: { code: failure.code, message: failure.message } });
}
function recordFrom(value: unknown, code: TaskRunFailure["code"], message: string): Record<string, unknown> | TaskRunFailure {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return failure(code, message);
}
function requiredString(value: unknown, name: string, code: TaskRunFailure["code"]): string | TaskRunFailure {
  if (typeof value === "string" && value.trim().length > 0)
    return value;
  return failure(code, `${name} muss ein nicht leerer String sein.`);
}
function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}
function failure(code: TaskRunFailure["code"], message: string): TaskRunFailure {
  return new TaskRunFailure(code, message);
}
