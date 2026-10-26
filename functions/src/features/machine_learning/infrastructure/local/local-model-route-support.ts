import {Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type LocalRuntimeWorkspaceContext} from "../../../../shared/local/local-runtime-workspace-context.js";
import {type ModelCatalogEntry} from "../../domain/entities/model-catalog-entry.js";
import {type ModelTag} from "../../domain/entities/model-tag.js";
import {isRequestError} from "./local-model-catalog-support.js";

export const ModelEntry = Type.Object({
  id: Type.String(), title: Type.String(), description: Type.String(), translations: Type.Optional(Type.Unknown()),
  task: Type.String(), languages: Type.Array(Type.String()), tags: Type.Array(Type.String()),
  scope: Type.Unknown(), runtime: Type.String(), artifactReference: Type.Unknown(), contract: Type.Unknown(),
  origin: Type.Optional(Type.String()),
});

export const ModelTagEntry = Type.Object({
  key: Type.String(), parent: Type.Optional(Type.String()),
  labels: Type.Record(Type.String(), Type.String()),
  synonyms: Type.Record(Type.String(), Type.Array(Type.String())),
});

export function tagDto(tag: ModelTag) {
  return {
    key: tag.key, ...(tag.parent === undefined ? {} : {parent: tag.parent}), labels: {...tag.labels},
    synonyms: Object.fromEntries(Object.entries(tag.synonyms ?? {}).map(([locale, words]) => [locale, [...words]])),
  };
}

export const failures = {400: ErrorResponse, 404: ErrorResponse, 415: ErrorResponse, 500: ErrorResponse, 503: ErrorResponse};

export function entryDto(entry: ModelCatalogEntry) {
  return {...entry, languages: [...entry.languages], tags: [...entry.tags]};
}

/** Fachliche Fehler als 400 mit Meldung, alles andere protokolliert als 500. */
export async function guarded<T>(
  workspace: LocalRuntimeWorkspaceContext, event: string, reply: FastifyReply, action: () => Promise<T>,
): Promise<T | FastifyReply> {
  try {
    return await action();
  } catch (error) {
    if (isRequestError(error)) return reply.code(400).send({error: error.message});
    workspace.logger.exception(`local_model_catalog.${event}`, error, {teamId: workspace.teamId});
    return reply.code(500).send({error: "Der Modellkatalog konnte nicht aktualisiert werden."});
  }
}
