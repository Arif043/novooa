import {and, asc, eq} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {employees, type Employees} from "../../../../db/schema.js";
import {type Employee, type EmployeeInput} from "../../domain/entities/employee.js";
import {type EmployeeStore} from "../../domain/repositories/employee-store.js";

export class SQLiteEmployeeStore implements EmployeeStore {
  constructor(private readonly database: RuntimeExecutor, private readonly now: () => Date = () => new Date()) {}

  async list(teamId: string): Promise<Employee[]> {
    const rows = await this.database.select().from(employees).where(eq(employees.team_id, teamId)).orderBy(asc(employees.name));
    return rows.map(employeeFrom).sort((a, b) => a.name.localeCompare(b.name, "de"));
  }

  async find(teamId: string, employeeId: string): Promise<Employee | null> {
    const [row] = await this.database.select().from(employees).where(owned(teamId, employeeId)).limit(1);
    return row === undefined ? null : employeeFrom(row);
  }

  async create(teamId: string, input: EmployeeInput): Promise<Employee> {
    const timestamp = this.now().toISOString();
    const [row] = await this.database.insert(employees).values({
      id: randomUUID(), team_id: teamId, name: input.name, constraint_text: input.constraint,
      skills_json: JSON.stringify(input.skills), created_at: timestamp, updated_at: timestamp,
    }).returning();
    return employeeFrom(row);
  }

  async update(teamId: string, employeeId: string, input: EmployeeInput): Promise<Employee | null> {
    const [row] = await this.database.update(employees).set({
      name: input.name, constraint_text: input.constraint, skills_json: JSON.stringify(input.skills),
      updated_at: this.now().toISOString(),
    }).where(owned(teamId, employeeId)).returning();
    return row === undefined ? null : employeeFrom(row);
  }

  async delete(teamId: string, employeeId: string): Promise<boolean> {
    const removed = await this.database.delete(employees).where(owned(teamId, employeeId)).returning({id: employees.id});
    return removed.length > 0;
  }
}

function owned(teamId: string, employeeId: string) {
  return and(eq(employees.team_id, teamId), eq(employees.id, employeeId));
}

function employeeFrom(row: Employees): Employee {
  return {
    id: row.id, name: row.name, constraint: row.constraint_text, skills: skillsFrom(row.skills_json),
    createdAt: row.created_at, updatedAt: row.updated_at,
  };
}

function skillsFrom(json: string): string[] {
  try {
    const parsed: unknown = JSON.parse(json);
    return Array.isArray(parsed) ? parsed.filter((skill): skill is string => typeof skill === "string") : [];
  } catch {
    return [];
  }
}
