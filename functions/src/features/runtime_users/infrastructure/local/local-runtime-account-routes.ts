import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply, type FastifyRequest} from "fastify";
import {type LoginAttemptLimiter} from "../../../../shared/local/local-runtime-login-rate-limiter.js";
import {type RuntimeUserRepository} from "../../domain/repositories/runtime-user-repository.js";
import {
  type ChangeOwnPassword,
  type LoadSetupState,
  type RecoverAdminAccess,
  type RedeemInvitation,
  type SetUpFirstAdmin,
  type SignIn,
} from "../../domain/usecases/runtime-access.js";
import {sendRuntimeUserFailure} from "./runtime-user-http-errors.js";
import {
  DisplayNameField,
  LicenseTokenField,
  LoginNameField,
  PasswordField,
  RuntimeUserDto,
  RuntimeUserFailure,
  SessionTokenDto,
} from "./runtime-user-dto.js";

export type AccountRoutesOptions = {
  setupState: LoadSetupState;
  requiresLicenseToken: () => boolean;
  setUp: SetUpFirstAdmin;
  signIn: SignIn;
  redeem: RedeemInvitation;
  recover: RecoverAdminAccess;
  changePassword: ChangeOwnPassword;
  users: Pick<RuntimeUserRepository, "find">;
  limiter: LoginAttemptLimiter;
};

const failures = {400: RuntimeUserFailure, 401: RuntimeUserFailure, 403: RuntimeUserFailure,
  404: RuntimeUserFailure, 409: RuntimeUserFailure, 429: RuntimeUserFailure};

/**
 * Einrichtung, Anmeldung, Einladung einlösen und Notzugang sind öffentlich (siehe Access-Hooks); jeder Versuch
 * kostet einen scrypt-Hash, deshalb greift die Ratenbegrenzung vor der Prüfung. `me` und das eigene Passwort
 * liegen hinter der Session-Prüfung.
 */
export const accountRoutes: FastifyPluginAsyncTypebox<AccountRoutesOptions> = async (app, options) => {
  app.get("/v1/setup", {schema: {response: {200: Type.Object({needsSetup: Type.Boolean(), requiresLicenseToken: Type.Boolean()})}}},
    async () => ({needsSetup: await options.setupState.needsSetup(), requiresLicenseToken: options.requiresLicenseToken()}));

  app.post("/v1/setup", {schema: {body: Type.Object({
    activationToken: LicenseTokenField, loginName: LoginNameField, displayName: DisplayNameField, password: PasswordField,
  }), response: {...failures, 201: RuntimeUserDto}}}, async (request, reply) => {
    try {
      return reply.code(201).send(await options.setUp.execute(request.body));
    } catch (error) {
      return sendRuntimeUserFailure(error, reply);
    }
  });

  app.post("/v1/auth/login", {schema: {body: Type.Object({loginName: LoginNameField, password: PasswordField}),
    response: {...failures, 200: SessionTokenDto}}}, async (request, reply) =>
    limited(request, reply, options.limiter, request.body.loginName, async () => ({token: await options.signIn.execute(request.body)})));

  app.post("/v1/auth/invitations/redeem", {schema: {body: Type.Object({code: Type.String({maxLength: 100}), password: PasswordField}),
    response: {...failures, 200: SessionTokenDto}}}, async (request, reply) =>
    limited(request, reply, options.limiter, undefined, async () => ({token: await options.redeem.execute(request.body)})));

  app.post("/v1/auth/recover", {schema: {body: Type.Object({
    activationToken: LicenseTokenField, loginName: LoginNameField, password: PasswordField,
  }), response: {...failures, 200: SessionTokenDto}}}, async (request, reply) =>
    limited(request, reply, options.limiter, request.body.loginName, async () => ({token: await options.recover.execute(request.body)})));

  app.get("/v1/auth/me", {schema: {response: {...failures, 200: RuntimeUserDto}}}, async (request, reply) => {
    const user = await options.users.find(request.actor.uid);
    return user ?? reply.code(404).send({error: "Das Konto gibt es nicht mehr.", code: "user_not_found"});
  });

  app.put("/v1/auth/password", {schema: {body: Type.Object({password: PasswordField}, {additionalProperties: false}),
    response: {...failures, 204: Type.Null()}}}, async (request, reply) => {
    try {
      await options.changePassword.execute(request.actor.uid, request.body.password);
      return reply.code(204).send(null);
    } catch (error) {
      return sendRuntimeUserFailure(error, reply);
    }
  });
};

/** Hinter einem Reverse Proxy ist `request.ip` die Adresse des Proxys; die Stufe je Konto greift trotzdem. */
async function limited<Result>(
  request: FastifyRequest, reply: FastifyReply, limiter: LoginAttemptLimiter, account: string | undefined,
  attempt: () => Promise<Result>,
): Promise<Result | FastifyReply> {
  const decision = await limiter.take({client: request.ip, account: account?.trim().toLowerCase()});
  if (!decision.allowed) {
    return reply.code(429).header("retry-after", String(decision.retryAfterSeconds)).send({
      error: `Zu viele Anmeldeversuche. Bitte in ${decision.retryAfterSeconds} Sekunden erneut versuchen.`,
    });
  }
  try {
    return await attempt();
  } catch (error) {
    return sendRuntimeUserFailure(error, reply);
  }
}
