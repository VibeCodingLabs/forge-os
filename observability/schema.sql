-- ForgeOS Observability Center SQLite schema
-- Local-first event ledger for agent calls, tool calls, model calls, compiler runs, jobs, costs, logs, artifacts, and wiki indexing.

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  source TEXT NOT NULL,
  type TEXT NOT NULL,
  project TEXT,
  agent TEXT,
  run_id TEXT,
  trace_id TEXT,
  span_id TEXT,
  severity TEXT DEFAULT 'info',
  message TEXT,
  payload_json TEXT,
  artifact_path TEXT
);

CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
CREATE INDEX IF NOT EXISTS idx_events_project ON events(project);
CREATE INDEX IF NOT EXISTS idx_events_agent ON events(agent);
CREATE INDEX IF NOT EXISTS idx_events_run ON events(run_id);
CREATE INDEX IF NOT EXISTS idx_events_trace ON events(trace_id);

CREATE TABLE IF NOT EXISTS agent_runs (
  id TEXT PRIMARY KEY,
  ts_start TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  ts_end TEXT,
  project TEXT,
  agent TEXT,
  goal TEXT,
  status TEXT NOT NULL DEFAULT 'running',
  parent_run_id TEXT,
  repo_path TEXT,
  worktree_path TEXT,
  model_route TEXT,
  sandbox_profile TEXT,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  estimated_cost_usd REAL DEFAULT 0,
  latency_ms INTEGER DEFAULT 0,
  summary TEXT,
  metadata_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_agent_runs_project ON agent_runs(project);
CREATE INDEX IF NOT EXISTS idx_agent_runs_agent ON agent_runs(agent);
CREATE INDEX IF NOT EXISTS idx_agent_runs_status ON agent_runs(status);

CREATE TABLE IF NOT EXISTS model_calls (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  run_id TEXT,
  project TEXT,
  agent TEXT,
  provider TEXT,
  model TEXT,
  route TEXT,
  direction TEXT CHECK(direction IN ('in','out','both')) DEFAULT 'both',
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  total_tokens INTEGER DEFAULT 0,
  prompt_chars INTEGER DEFAULT 0,
  response_chars INTEGER DEFAULT 0,
  latency_ms INTEGER DEFAULT 0,
  status TEXT DEFAULT 'ok',
  error TEXT,
  estimated_cost_usd REAL DEFAULT 0,
  request_artifact TEXT,
  response_artifact TEXT,
  metadata_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_model_calls_run ON model_calls(run_id);
CREATE INDEX IF NOT EXISTS idx_model_calls_provider ON model_calls(provider);
CREATE INDEX IF NOT EXISTS idx_model_calls_model ON model_calls(model);
CREATE INDEX IF NOT EXISTS idx_model_calls_ts ON model_calls(ts);

CREATE TABLE IF NOT EXISTS tool_calls (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  run_id TEXT,
  project TEXT,
  agent TEXT,
  tool_name TEXT NOT NULL,
  tool_type TEXT,
  command TEXT,
  cwd TEXT,
  exit_code INTEGER,
  latency_ms INTEGER DEFAULT 0,
  status TEXT DEFAULT 'ok',
  stdout_artifact TEXT,
  stderr_artifact TEXT,
  metadata_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_tool_calls_run ON tool_calls(run_id);
CREATE INDEX IF NOT EXISTS idx_tool_calls_tool ON tool_calls(tool_name);
CREATE INDEX IF NOT EXISTS idx_tool_calls_ts ON tool_calls(ts);

CREATE TABLE IF NOT EXISTS compiler_runs (
  id TEXT PRIMARY KEY,
  ts_start TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  ts_end TEXT,
  project TEXT,
  compiler TEXT NOT NULL,
  source_type TEXT,
  source_path TEXT,
  output_type TEXT,
  output_path TEXT,
  status TEXT DEFAULT 'running',
  diagnostics_json TEXT,
  metadata_json TEXT
);

CREATE TABLE IF NOT EXISTS artifacts (
  id TEXT PRIMARY KEY,
  ts TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  project TEXT,
  run_id TEXT,
  kind TEXT NOT NULL,
  path TEXT NOT NULL,
  sha256 TEXT,
  size_bytes INTEGER,
  summary TEXT,
  metadata_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_artifacts_project ON artifacts(project);
CREATE INDEX IF NOT EXISTS idx_artifacts_run ON artifacts(run_id);
CREATE INDEX IF NOT EXISTS idx_artifacts_kind ON artifacts(kind);

CREATE TABLE IF NOT EXISTS wiki_pages (
  id TEXT PRIMARY KEY,
  ts_created TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  ts_updated TEXT,
  project TEXT,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  path TEXT NOT NULL,
  kind TEXT DEFAULT 'note',
  tags TEXT,
  summary TEXT,
  source_artifact_id TEXT,
  metadata_json TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_wiki_project_slug ON wiki_pages(project, slug);
CREATE INDEX IF NOT EXISTS idx_wiki_project ON wiki_pages(project);
CREATE INDEX IF NOT EXISTS idx_wiki_kind ON wiki_pages(kind);

CREATE TABLE IF NOT EXISTS wiki_edges (
  id TEXT PRIMARY KEY,
  from_page TEXT NOT NULL,
  to_page TEXT NOT NULL,
  relation TEXT NOT NULL,
  weight REAL DEFAULT 1.0,
  metadata_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_wiki_edges_from ON wiki_edges(from_page);
CREATE INDEX IF NOT EXISTS idx_wiki_edges_to ON wiki_edges(to_page);

CREATE VIEW IF NOT EXISTS v_recent_events AS
SELECT ts, source, type, project, agent, run_id, severity, message
FROM events
ORDER BY ts DESC
LIMIT 200;

CREATE VIEW IF NOT EXISTS v_model_costs AS
SELECT project, agent, provider, model,
       COUNT(*) AS calls,
       SUM(input_tokens) AS input_tokens,
       SUM(output_tokens) AS output_tokens,
       SUM(total_tokens) AS total_tokens,
       ROUND(SUM(estimated_cost_usd), 6) AS estimated_cost_usd,
       ROUND(AVG(latency_ms), 2) AS avg_latency_ms
FROM model_calls
GROUP BY project, agent, provider, model
ORDER BY estimated_cost_usd DESC;
