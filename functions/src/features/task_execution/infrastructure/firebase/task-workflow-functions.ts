import {
  HttpsError,
  isSignedIn,
  onCall,
} from "firebase-functions/v2/https";
import {onTaskDispatched} from "firebase-functions/v2/tasks";
import {createGenkitTaskWorkflow} from "../genkit/task-workflow.js";
import {
  type ReviewTaskWorkflowInput,
  type StartTaskWorkflowInput,
  type TaskRunDispatch,
  type TaskWorkflowContext,
} from "../../domain/usecases/task-workflow.js";
import {geminiApiKey} from "../../../../shared/genkit/gemini-secret.js";
import {withExceptionLogging} from "../../../../shared/logging/logger.js";
import {
  twilioAccountSid,
  twilioAuthToken,
} from "../../../communication/infrastructure/twilio/twilio-secrets.js";
import {
  mailConnectorEncryptionKey,
  microsoftGraphClientSecret,
} from "../../../communication/infrastructure/microsoft_graph/microsoft-graph-config.js";
import {createCloudTaskRuntime} from "./cloud-task-runtime-factory.js";
import {languageModelEncryptionKey} from "../../../language_models/infrastructure/firebase/language-model-encryption.js";

const workerSecrets = [
  twilioAccountSid,
  twilioAuthToken,
  microsoftGraphClientSecret,
  mailConnectorEncryptionKey,
  geminiApiKey,
  languageModelEncryptionKey,
];

const taskRuntime = createCloudTaskRuntime();
const taskWorkflow = createGenkitTaskWorkflow(taskRuntime);

const callableOptions = {
  authPolicy: isSignedIn(),
  invoker: "public" as const,
};

export const runTaskDefinitionFlow = onCall(
  callableOptions,
  async (request) => taskWorkflow.start(
    startInputFrom(request.data),
    workflowContextFrom(request.auth),
  ),
);

export const reviewTaskRun = onCall(
  callableOptions,
  async (request) => taskWorkflow.review(
    reviewInputFrom(request.data),
    workflowContextFrom(request.auth),
  ),
);

export const runTaskRunTask = onTaskDispatched<TaskRunDispatch>(
  {
    region: "europe-west3",
    secrets: workerSecrets,
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 30,
      maxBackoffSeconds: 300,
    },
    rateLimits: {
      maxConcurrentDispatches: 10,
      maxDispatchesPerSecond: 5,
    },
  },
  async (request) => withExceptionLogging(
    "task_run_task.handler_failed",
    () => taskWorkflow.dispatch(dispatchFrom(request.data)),
  ),
);

function startInputFrom(data: unknown): StartTaskWorkflowInput {
  const input = recordFrom(data, "Die Task-Ausfuehrung erwartet ein Objekt.");
  return {
    taskId: requiredString(input.taskId, "taskId"),
    context: optionalString(input.context),
  };
}

function reviewInputFrom(data: unknown): ReviewTaskWorkflowInput {
  const input = recordFrom(data, "Die Run-Pruefung erwartet ein Objekt.");
  const decision = input.decision;
  if (decision !== "approve" && decision !== "reject") {
    throw invalidInput("decision muss approve oder reject sein.");
  }
  return {
    runId: requiredString(input.runId, "runId"),
    decision,
    output: optionalString(input.output),
    formValues: recordFrom(input.formValues ?? {}, "formValues muss ein Objekt sein."),
  };
}

function dispatchFrom(data: unknown): TaskRunDispatch {
  const input = recordFrom(data, "Die Task-Payload erwartet ein Objekt.");
  const mode = input.mode;
  if (mode !== "start" && mode !== "resume") {
    throw invalidInput("mode muss start oder resume sein.");
  }
  return {
    teamId: requiredString(input.teamId, "teamId"),
    runId: requiredString(input.runId, "runId"),
    mode,
  };
}

function workflowContextFrom(auth: {uid: string} | undefined): TaskWorkflowContext {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Anmeldung ist erforderlich.");
  return {uid: auth.uid};
}

function recordFrom(value: unknown, message: string): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw invalidInput(message);
}

function requiredString(value: unknown, name: string): string {
  if (typeof value === "string" && value.trim().length > 0) return value;
  throw invalidInput(`${name} muss ein nicht leerer String sein.`);
}

function optionalString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function invalidInput(message: string): HttpsError {
  return new HttpsError("invalid-argument", message);
}
