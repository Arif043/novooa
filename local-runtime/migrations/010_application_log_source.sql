ALTER TABLE application_logs
  ADD COLUMN source TEXT NOT NULL DEFAULT 'runtime'
  CHECK(source IN ('client', 'runtime'));
