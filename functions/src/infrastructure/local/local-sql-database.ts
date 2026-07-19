export type SqlValue = string | number | null;
export type SqlParameters = readonly SqlValue[];
export type SqlRow = Record<string, unknown>;

export interface LocalSqlDatabase {
  get<T extends SqlRow>(sql: string, parameters?: SqlParameters): Promise<T | null>;
  all<T extends SqlRow>(sql: string, parameters?: SqlParameters): Promise<T[]>;
  run(sql: string, parameters?: SqlParameters): Promise<void>;
  transaction<T>(operation: () => Promise<T>): Promise<T>;
}
