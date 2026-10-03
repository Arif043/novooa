import {and, eq, ne} from "drizzle-orm";
import {z} from "zod";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {employees} from "../../../../db/schema.js";
import {
  EmployeeValidationError,
  employeeInputFrom,
  employeeLimits,
  sameEmployeeName,
} from "../../../employees/domain/entities/employee.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {type TransferTeamMapping} from "../../domain/entities/transfer-team-mapping.js";
import {transferDataEntry, type TransferArchiveReader, type TransferArchiveWriter} from "../../domain/repositories/transfer-archive.js";
import {type TransferSection} from "../../domain/repositories/transfer-section.js";
import {sectionPayload, stagedRows, type SqliteTransferSectionImporter, type StagedSectionImport} from "./sqlite-transfer-section-importer.js";

const timestamp = z.string().min(1).max(64);

const employeesTransferPayload = z.object({
  employees: z.array(z.object({
    id: z.string().min(1).max(200),
    name: z.string().max(employeeLimits.maximumNameLength * 4),
    constraint: z.string().max(employeeLimits.maximumConstraintLength * 4),
    skills: z.array(z.string()).max(employeeLimits.maximumSkills * 4),
    createdAt: timestamp,
    updatedAt: timestamp,
  })).max(10_000),
});

type EmployeesTransferPayload = z.infer<typeof employeesTransferPayload>;

/**
 * Mitarbeiter im Export: Rahmenbedingung und Skill-Namen. Die Skills selbst gehören zum Bereich „Fähigkeiten“; fehlen
 * sie im Ziel, meldet der Lauf es später klar. Gleiche IDs werden überschrieben; ein gleicher Name unter anderer ID
 * bekommt ein „ (2)“, weil Namen je Team eindeutig sind und die Auswahl im Baustein sonst nicht eindeutig wäre.
 */
export class SqliteEmployeesTransferSection implements TransferSection, SqliteTransferSectionImporter {
  readonly category = "employees" as const;

  constructor(private readonly database: RuntimeExecutor) {}

  async exportTo(writer: TransferArchiveWriter, teamId: string): Promise<number> {
    const rows = await this.database.select().from(employees).where(eq(employees.team_id, teamId));
    const payload: EmployeesTransferPayload = {
      employees: rows.map((row) => ({
        id: row.id, name: row.name, constraint: row.constraint_text, skills: skillsFrom(row.skills_json),
        createdAt: row.created_at, updatedAt: row.updated_at,
      })),
    };
    await writer.addJson(transferDataEntry("employees"), payload);
    return payload.employees.length;
  }

  async stage(reader: TransferArchiveReader, mapping: TransferTeamMapping): Promise<StagedSectionImport> {
    const payload = await sectionPayload(reader, "employees", employeesTransferPayload);
    const validated = payload.employees.map((employee) => ({...employee, ...inputOf(employee)}));
    return stagedRows(validated.length, (executor) => commitEmployees(executor, validated, mapping.targetTeamId));
  }
}

function inputOf(employee: EmployeesTransferPayload["employees"][number]) {
  try {
    return employeeInputFrom({name: employee.name, constraint: employee.constraint, skills: employee.skills});
  } catch (error) {
    if (error instanceof EmployeeValidationError) throw new InvalidTransferArchiveError(`Ein Mitarbeiter im Export ist ungültig: ${error.message}`);
    throw error;
  }
}

async function commitEmployees(
  executor: RuntimeExecutor,
  payload: Array<EmployeesTransferPayload["employees"][number] & {name: string; constraint: string; skills: string[]}>,
  teamId: string,
): Promise<void> {
  for (const employee of payload) {
    const name = await freeName(executor, teamId, employee.id, employee.name);
    const values = {name, constraint_text: employee.constraint, skills_json: JSON.stringify(employee.skills), updated_at: employee.updatedAt};
    await executor.insert(employees).values({id: employee.id, team_id: teamId, created_at: employee.createdAt, ...values})
      .onConflictDoUpdate({target: employees.id, set: values, setWhere: eq(employees.team_id, teamId)});
  }
}

/** Der Name, unter dem der Mitarbeiter im Ziel landet: unverändert, sonst mit „ (2)“, „ (3)“ … */
async function freeName(executor: RuntimeExecutor, teamId: string, ownId: string, wanted: string): Promise<string> {
  const others = await executor.select({name: employees.name}).from(employees).where(and(eq(employees.team_id, teamId), ne(employees.id, ownId)));
  const taken = (candidate: string) => others.some((other) => sameEmployeeName(other.name, candidate));
  if (!taken(wanted)) return wanted;
  for (let counter = 2; ; counter++) {
    const suffix = ` (${counter})`;
    const candidate = `${wanted.slice(0, employeeLimits.maximumNameLength - suffix.length)}${suffix}`;
    if (!taken(candidate)) return candidate;
  }
}

function skillsFrom(json: string): string[] {
  try {
    const parsed: unknown = JSON.parse(json);
    return Array.isArray(parsed) ? parsed.filter((skill): skill is string => typeof skill === "string") : [];
  } catch {
    return [];
  }
}
