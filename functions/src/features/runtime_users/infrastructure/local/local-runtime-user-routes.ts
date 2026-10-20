import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {
  type CreateUser,
  type DeleteUser,
  type ListUsers,
  type ResetUserPassword,
  type UpdateUser,
} from "../../domain/usecases/runtime-user-management.js";
import {sendRuntimeUserFailure} from "./runtime-user-http-errors.js";
import {
  DisplayNameField,
  InvitationDto,
  LoginNameField,
  RuntimeRoleSchema,
  RuntimeUserDto,
  RuntimeUserFailure,
} from "./runtime-user-dto.js";

export type UserRoutesOptions = {
  list: ListUsers;
  create: CreateUser;
  update: UpdateUser;
  resetPassword: ResetUserPassword;
  remove: DeleteUser;
  notifier: {publish(topic: string): void};
};

const failures = {400: RuntimeUserFailure, 404: RuntimeUserFailure, 409: RuntimeUserFailure};
const UidParams = Type.Object({uid: Type.String({minLength: 1, maxLength: 200})});

/** Benutzerverwaltung; nur für Admins (siehe `local-runtime-role-policy.ts`). */
export const userRoutes: FastifyPluginAsyncTypebox<UserRoutesOptions> = async (app, options) => {
  const changed = () => options.notifier.publish("users");

  app.get("/v1/users", {schema: {response: {200: Type.Object({
    items: Type.Array(RuntimeUserDto), maxUsers: Type.Union([Type.Integer(), Type.Null()]),
  })}}}, async () => {
    const {users, maxUsers} = await options.list.execute();
    return {items: users, maxUsers};
  });

  app.post("/v1/users", {schema: {
    body: Type.Object({loginName: LoginNameField, displayName: DisplayNameField, role: RuntimeRoleSchema}),
    response: {...failures, 201: Type.Object({user: RuntimeUserDto, invitation: InvitationDto})},
  }}, async (request, reply) => {
    try {
      const created = await options.create.execute(request.body);
      changed();
      return reply.code(201).send(created);
    } catch (error) {
      return sendRuntimeUserFailure(error, reply);
    }
  });

  app.put("/v1/users/:uid", {schema: {
    params: UidParams, body: Type.Object({displayName: Type.Optional(DisplayNameField), role: Type.Optional(RuntimeRoleSchema)}),
    response: {...failures, 200: RuntimeUserDto},
  }}, async (request, reply) => {
    try {
      const user = await options.update.execute(request.params.uid, request.body);
      changed();
      return user;
    } catch (error) {
      return sendRuntimeUserFailure(error, reply);
    }
  });

  app.post("/v1/users/:uid/invitation", {schema: {params: UidParams, response: {...failures, 201: InvitationDto}}},
    async (request, reply) => {
      try {
        const invitation = await options.resetPassword.execute(request.actor.uid, request.params.uid);
        changed();
        return reply.code(201).send(invitation);
      } catch (error) {
        return sendRuntimeUserFailure(error, reply);
      }
    });

  app.delete("/v1/users/:uid", {schema: {params: UidParams, response: {...failures, 204: Type.Null()}}},
    async (request, reply) => {
      try {
        await options.remove.execute(request.actor.uid, request.params.uid);
        changed();
        return reply.code(204).send(null);
      } catch (error) {
        return sendRuntimeUserFailure(error, reply);
      }
    });
};
