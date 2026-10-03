import {
  EmployeeNameTakenError,
  EmployeeNotFoundError,
  employeeInputFrom,
  sameEmployeeName,
  type Employee,
  type EmployeeInput,
} from "../entities/employee.js";
import {type EmployeeStore} from "../repositories/employee-store.js";

export class ListEmployees {
  constructor(private readonly store: EmployeeStore) {}

  execute(teamId: string): Promise<Employee[]> {
    return this.store.list(teamId);
  }
}

export class CreateEmployee {
  constructor(private readonly store: EmployeeStore) {}

  async execute(teamId: string, raw: EmployeeInput): Promise<Employee> {
    const input = employeeInputFrom(raw);
    await ensureNameFree(this.store, teamId, input.name);
    return this.store.create(teamId, input);
  }
}

export class UpdateEmployee {
  constructor(private readonly store: EmployeeStore) {}

  async execute(teamId: string, employeeId: string, raw: EmployeeInput): Promise<Employee> {
    const input = employeeInputFrom(raw);
    await ensureNameFree(this.store, teamId, input.name, employeeId);
    const updated = await this.store.update(teamId, employeeId, input);
    if (updated === null) throw new EmployeeNotFoundError(employeeId);
    return updated;
  }
}

export class DeleteEmployee {
  constructor(private readonly store: EmployeeStore) {}

  async execute(teamId: string, employeeId: string): Promise<void> {
    if (!(await this.store.delete(teamId, employeeId))) throw new EmployeeNotFoundError(employeeId);
  }
}

/** Namen sind je Team eindeutig (ohne Groß-/Kleinschreibung), damit die Auswahl im Baustein eindeutig bleibt. */
async function ensureNameFree(store: EmployeeStore, teamId: string, name: string, ownId?: string): Promise<void> {
  const taken = (await store.list(teamId)).some((employee) => employee.id !== ownId && sameEmployeeName(employee.name, name));
  if (taken) throw new EmployeeNameTakenError(name);
}
