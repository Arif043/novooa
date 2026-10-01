import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply, type FastifySchemaValidationError} from "fastify";
import {ErrorResponse, JsonObject} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {TaskRunFailure} from "../../domain/entities/task-run-failure.js";

export type TaskRunRoutesOptions = {notifier: {publish(topic: string): void}};

const NonBlank = Type.String({minLength: 1, pattern: "\\S"});
const StartRun = Type.Object({taskId: NonBlank, context: Type.Optional(Type.String())});
const ReviewRun = Type.Object({
  runId: NonBlank,
  decision: Type.Union([Type.Literal("approve"), Type.Literal("reject")]),
  output: Type.Optional(Type.String()),
  formValues: Type.Optional(JsonObject),
});
/** Gleicher Fehlervertrag wie die Cloud-Callables: `{failure: {code, message}}`. */
const FailureResponse = Type.Object({failure: Type.Object({code: Type.String(), message: Type.String()})});
const errorResponses = {400: FailureResponse, 500: ErrorResponse};

export const taskRunRoutes: FastifyPluginAsyncTypebox<TaskRunRoutesOptions> = async (app, {notifier}) => {
  /** Ein Run ändert seinen Status nie ohne eine begleitende Aktivität. */
  const publishRunChanges = () => {
    notifier.publish("task-runs");
    notifier.publish("task-activities");
  };

  app.post("/v1/task-runs", {
    attachValidation: true,
    schema: {body: StartRun, response: {...errorResponses,
      202: Type.Object({runId: Type.String(), taskId: Type.String(), status: Type.Literal("queued")})}},
  }, async (request, reply) => {
    if (request.validationError) return rejectStart(request.validationError.validation, reply);
    const {taskWorkflow, userId} = request.workspace;
    return runSafely(request.workspace, "start_failed", reply, async () => {
      const output = await taskWorkflow.start({taskId: request.body.taskId, context: request.body.context ?? ""}, {uid: userId});
      publishRunChanges();
      return reply.code(202).send(output);
    });
  });

  app.post("/v1/task-runs/review", {
    attachValidation: true,
    schema: {body: ReviewRun, response: {...errorResponses,
      200: Type.Object({runId: Type.String(), status: Type.Union([Type.Literal("queued"), Type.Literal("rejected")])})}},
  }, async (request, reply) => {
    if (request.validationError) return rejectReview(request.validationError.validation, reply);
    const {taskWorkflow, userId} = request.workspace;
    const {runId, decision, output, formValues} = request.body;
    return runSafely(request.workspace, "review_failed", reply, async () => {
      const result = await taskWorkflow.review({runId, decision, output: output ?? "", formValues: formValues ?? {}}, {uid: userId});
      publishRunChanges();
      return reply.code(200).send(result);
    });
  });
};

async function runSafely(
  workspace: LocalRuntimeWorkspaceContext, event: string, reply: FastifyReply, action: () => Promise<FastifyReply>,
): Promise<FastifyReply> {
  try {
    return await action();
  } catch (error) {
    workspace.logger.exception(`local_task_run_routes.${event}`, error, {userId: workspace.userId});
    return reply.code(500).send({error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."});
  }
}

function rejectStart(errors: FastifySchemaValidationError[], reply: FastifyReply): FastifyReply {
  const failure = involves(errors, "taskId")
    ? new TaskRunFailure("invalidTaskId", "taskId muss ein nicht leerer String sein.")
    : new TaskRunFailure("invalidRequest", "Die Aufgabenausführung ist ungültig.");
  return reply.code(400).send({failure: {code: failure.code, message: failure.message}});
}

function rejectReview(errors: FastifySchemaValidationError[], reply: FastifyReply): FastifyReply {
  const failure = involves(errors, "decision")
    ? new TaskRunFailure("invalidReviewDecision", "decision muss approve oder reject sein.")
    : involves(errors, "formValues")
      ? new TaskRunFailure("invalidFormValues", "formValues muss ein Objekt sein.")
      : new TaskRunFailure("invalidRequest", "Die Run-Prüfung ist ungültig.");
  return reply.code(400).send({failure: {code: failure.code, message: failure.message}});
}

/** Betrifft der Schema-Fehler ein bestimmtes Feld (auch als fehlende Pflichtangabe)? */
function involves(errors: FastifySchemaValidationError[], field: string): boolean {
  return errors.some((error) =>
    error.instancePath.startsWith(`/${field}`) || (error.params as {missingProperty?: string}).missingProperty === field);
}
