import {type RuntimeExecutor} from "../../db/database.js";
import {teamMembers, teams, userProfiles} from "../../db/schema.js";

/**
 * Identität der aktiven Lizenz: Team und Nutzer, für die die Runtime gerade arbeitet. Kann zur
 * Laufzeit wechseln (neue Lizenz) — dann entsteht eine neue Composition. Pfade und andere
 * Prozess-Infrastruktur gehören bewusst nicht hierher, sondern in `LocalRuntimeHost`.
 */
export type LocalRuntimeWorkspace = {
  teamId: string;
  teamName: string;
  userId: string;
};

/** Legt Nutzer, Team und Mitgliedschaft an, falls sie fehlen; vorhandene Einträge bleiben. */
export async function ensureLocalRuntimeWorkspace(
  database: RuntimeExecutor,
  workspace: LocalRuntimeWorkspace,
): Promise<void> {
  await database.transaction(async (tx) => {
    await tx.insert(userProfiles).values({uid: workspace.userId, display_name: "Lokaler Benutzer"})
      .onConflictDoNothing();
    await tx.insert(teams).values({id: workspace.teamId, name: workspace.teamName, owner_uid: workspace.userId})
      .onConflictDoNothing();
    await tx.insert(teamMembers).values({team_id: workspace.teamId, uid: workspace.userId,
      role: "admin"}).onConflictDoNothing();
  });
}
