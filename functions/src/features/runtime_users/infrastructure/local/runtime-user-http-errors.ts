import {type FastifyReply} from "fastify";
import {RuntimeUserError, type RuntimeUserErrorCode} from "../../domain/entities/runtime-user-error.js";

const statusByCode: Record<RuntimeUserErrorCode, number> = {
  invalid_input: 400,
  invalid_credentials: 401,
  invalid_invitation: 401,
  license_token_mismatch: 403,
  user_not_found: 404,
  already_set_up: 409,
  login_name_taken: 409,
  user_limit_reached: 409,
  last_admin: 409,
  own_account: 409,
  workspace_owner: 409,
};

/** Antwortet auf fachliche Fehler mit Status, Meldung und Code; alles andere geht an den Fehler-Handler. */
export function sendRuntimeUserFailure(error: unknown, reply: FastifyReply): FastifyReply {
  if (!(error instanceof RuntimeUserError)) throw error;
  return reply.code(statusByCode[error.code]).send({error: error.message, code: error.code});
}
