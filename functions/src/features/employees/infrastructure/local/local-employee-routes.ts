import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type FastifyReply} from "fastify";
import {ErrorResponse, ItemsOf} from "../../../../shared/local/local-runtime-http-schemas.js";
import {EmployeeNameTakenError, EmployeeNotFoundError, EmployeeValidationError, employeeLimits} from "../../domain/entities/employee.js";
import {type CreateEmployee, type DeleteEmployee, type ListEmployees, type UpdateEmployee} from "../../domain/usecases/employee-library.js";

export type EmployeeRoutesOptions = {
  list: ListEmployees;
  create: CreateEmployee;
  update: UpdateEmployee;
  remove: DeleteEmployee;
  notifier: {publish(topic: string): void};
};

const EmployeeDto = Type.Object({
  id: Type.String(), name: Type.String(), constraint: Type.String(), skills: Type.Array(Type.String()),
  createdAt: Type.String(), updatedAt: Type.String(),
});
// Die Längen prüft die Domäne mit lesbaren Meldungen; das Schema begrenzt nur grob die Größe der Anfrage.
const EmployeeBody = Type.Object({
  name: Type.String({maxLength: employeeLimits.maximumNameLength * 4}),
  constraint: Type.String({maxLength: employeeLimits.maximumConstraintLength * 4}),
  skills: Type.Array(Type.String({maxLength: 400}), {maxItems: employeeLimits.maximumSkills * 4}),
});
const IdParams = Type.Object({employeeId: Type.String({minLength: 1, maxLength: 100})});
const failures = {400: ErrorResponse, 404: ErrorResponse, 409: ErrorResponse};

export const employeeRoutes: FastifyPluginAsyncTypebox<EmployeeRoutesOptions> = async (app, options) => {
  app.get("/v1/employees", {schema: {response: {200: ItemsOf(EmployeeDto)}}},
    async (request) => ({items: await options.list.execute(request.workspace.teamId)}));

  app.post("/v1/employees", {schema: {body: EmployeeBody, response: {...failures, 201: EmployeeDto}}}, async (request, reply) => {
    try {
      const employee = await options.create.execute(request.workspace.teamId, request.body);
      options.notifier.publish("employees");
      return reply.code(201).send(employee);
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.put("/v1/employees/:employeeId", {
    schema: {params: IdParams, body: EmployeeBody, response: {...failures, 200: EmployeeDto}},
  }, async (request, reply) => {
    try {
      const employee = await options.update.execute(request.workspace.teamId, request.params.employeeId, request.body);
      options.notifier.publish("employees");
      return employee;
    } catch (error) {
      return failure(error, reply);
    }
  });

  app.delete("/v1/employees/:employeeId", {
    schema: {params: IdParams, response: {...failures, 200: Type.Object({})}},
  }, async (request, reply) => {
    try {
      await options.remove.execute(request.workspace.teamId, request.params.employeeId);
      options.notifier.publish("employees");
      return {};
    } catch (error) {
      return failure(error, reply);
    }
  });
};

function failure(error: unknown, reply: FastifyReply): FastifyReply {
  if (error instanceof EmployeeValidationError) return reply.code(400).send({error: error.message});
  if (error instanceof EmployeeNotFoundError) return reply.code(404).send({error: error.message});
  if (error instanceof EmployeeNameTakenError) return reply.code(409).send({error: error.message});
  throw error;
}
