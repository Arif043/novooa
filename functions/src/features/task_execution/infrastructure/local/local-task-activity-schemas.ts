import {Type} from "@fastify/type-provider-typebox";
import {JsonObject, NonEmptyString} from "../../../../shared/local/local-runtime-http-schemas.js";

const NullableString = Type.Union([Type.String(), Type.Null()]);
const Person = Type.Union([Type.Object({uid: Type.String(), displayName: Type.String()}), Type.Null()]);
export const TaskRun = Type.Object({
  runId: Type.String(), taskId: Type.String(), taskTitle: Type.String(), status: Type.String(),
  waitingNodeId: NullableString, finalOutput: Type.String(), reviewOutput: NullableString,
  interaction: Type.Unknown(), error: Type.Unknown(), createdAt: Type.String(), updatedAt: Type.String(),
  startedAt: NullableString, completedAt: NullableString, triggerType: NullableString, startedBy: Person,
});
/** Woher der Lauf kommt: von Hand gestartet (Person) oder durch einen Auslöser; wer die Freigabe beantwortet hat. */
const RunOrigin = Type.Object({startedBy: Person, reviewedBy: Person, triggerType: NullableString});
export const Activity = Type.Object({
  origin: RunOrigin,
  id: Type.String(), runId: Type.String(), taskId: Type.String(), taskTitle: Type.String(), target: Type.String(),
  status: Type.String(), occurredAt: Type.String(), nodeId: NullableString, primitive: NullableString,
  input: Type.String(), output: Type.String(), outputs: JsonObject, message: Type.String(), failureCode: NullableString,
  failureDetails: Type.Union([Type.Record(Type.String(), Type.String()), Type.Null()]),
  console: Type.Object({stdout: Type.String(), stderr: Type.String()}),
  conversation: Type.Array(Type.Unknown()),
  /** Folgen des Bausteins (`RunEffect`), wie gespeichert. */
  effects: Type.Array(Type.Unknown()),
  /** Umschließender Zweig/Schleife und Runde; `null` auf oberster Ebene. */
  parentNodeId: NullableString, iteration: Type.Union([Type.Integer(), Type.Null()]), selectedBranchId: NullableString,
});
export const NewActivity = Type.Object({
  id: NonEmptyString(), runId: NonEmptyString(), taskId: NonEmptyString(), taskTitle: NonEmptyString(),
  target: NonEmptyString(), status: NonEmptyString(), occurredAt: NonEmptyString(),
  nodeId: Type.Optional(NullableString), primitive: Type.Optional(NullableString),
  input: Type.Optional(Type.String()), output: Type.Optional(Type.String()),
  outputs: Type.Optional(JsonObject), message: Type.Optional(Type.String()),
});
