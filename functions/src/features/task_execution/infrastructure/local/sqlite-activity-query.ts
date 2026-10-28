import {eq} from "drizzle-orm";
import {alias} from "drizzle-orm/sqlite-core";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {activities, taskRuns, userProfiles} from "../../../../db/schema.js";

const starter = alias(userProfiles, "starter");
const reviewer = alias(userProfiles, "reviewer");

/** Aktivitäten samt Lauf und den beteiligten Personen; Filter und Reihenfolge setzt der Aufrufer. */
export function activityRowsQuery(database: RuntimeExecutor) {
  return database.select({id: activities.id, run_id: activities.run_id, task_id: taskRuns.task_id,
    node_id: activities.node_id, target: activities.target, primitive: activities.primitive, title: activities.title,
    status: activities.status, input: activities.input, output: activities.output, outputs_json: activities.outputs_json,
    message: activities.message, failure_code: activities.failure_code, failure_details_json: activities.failure_details_json,
    console_json: activities.console_json, conversation_json: activities.conversation_json, effects_json: activities.effects_json,
    parent_node_id: activities.parent_node_id, iteration: activities.iteration, selected_branch_id: activities.selected_branch_id,
    created_at: activities.created_at, trigger_type: taskRuns.trigger_type,
    started_by_uid: taskRuns.started_by_uid, started_by_name: starter.display_name,
    reviewed_by_uid: taskRuns.reviewed_by_uid, reviewed_by_name: reviewer.display_name}).from(activities)
    .innerJoin(taskRuns, eq(taskRuns.id, activities.run_id))
    .leftJoin(starter, eq(starter.uid, taskRuns.started_by_uid))
    .leftJoin(reviewer, eq(reviewer.uid, taskRuns.reviewed_by_uid));
}

/** Läufe mit Zeiten und Herkunft; Filter und Reihenfolge setzt der Aufrufer. */
export function taskRunRowsQuery(database: RuntimeExecutor) {
  return database.select({id: taskRuns.id, task_id: taskRuns.task_id, task_title: taskRuns.task_title,
    status: taskRuns.status, waiting_node_id: taskRuns.waiting_node_id, final_output: taskRuns.final_output,
    review_output: taskRuns.review_output, interaction_json: taskRuns.interaction_json, error_json: taskRuns.error_json,
    created_at: taskRuns.created_at, updated_at: taskRuns.updated_at, started_at: taskRuns.started_at,
    completed_at: taskRuns.completed_at, trigger_type: taskRuns.trigger_type,
    started_by_uid: taskRuns.started_by_uid, started_by_name: starter.display_name}).from(taskRuns)
    .leftJoin(starter, eq(starter.uid, taskRuns.started_by_uid));
}
