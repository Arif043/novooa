export function insertRunSql() {
  return `INSERT INTO task_runs(id, team_id, task_id, task_title, status, context,
    input_json, source, trigger_id, trigger_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
}

export function loadRunSql() {
  return `SELECT id, task_id, task_title, context, input_json, resume_state_json,
    status FROM task_runs WHERE team_id = ? AND id = ?`;
}

export function statusSql(field: string) {
  return `UPDATE task_runs SET status = ?, ${field} = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP WHERE team_id = ? AND id = ?`;
}

export function successSql() {
  return `UPDATE task_runs SET status = 'succeeded', final_output = ?,
    completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE team_id = ? AND id = ?`;
}

export function waitingSql() {
  return `UPDATE task_runs SET status = 'waitingForApproval', final_output = ?,
    waiting_node_id = ?, review_instruction = ?, review_output = ?,
    resume_state_json = ?, paused_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE team_id = ? AND id = ?`;
}

export function failedSql() {
  return `UPDATE task_runs SET status = 'failed', error_json = ?,
    completed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE team_id = ? AND id = ?`;
}

export function rejectSql() {
  return `UPDATE task_runs SET status = 'rejected',
    reviewed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE team_id = ? AND id = ?`;
}

export function approveSql() {
  return `UPDATE task_runs SET status = 'queued', approved_output = ?,
    reviewed_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE team_id = ? AND id = ?`;
}
