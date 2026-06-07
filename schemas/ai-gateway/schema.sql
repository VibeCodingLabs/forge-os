PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  auth_type TEXT NOT NULL CHECK (auth_type IN ('none','api_key','oauth','local')),
  base_url TEXT,
  docs_url TEXT,
  status TEXT NOT NULL DEFAULT 'unknown',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS models (
  id TEXT PRIMARY KEY,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  model_id TEXT NOT NULL,
  display_name TEXT,
  is_free INTEGER NOT NULL DEFAULT 0 CHECK (is_free IN (0,1)),
  context_window INTEGER,
  max_output_tokens INTEGER,
  supports_tools INTEGER NOT NULL DEFAULT 0 CHECK (supports_tools IN (0,1)),
  supports_json INTEGER NOT NULL DEFAULT 0 CHECK (supports_json IN (0,1)),
  supports_vision INTEGER NOT NULL DEFAULT 0 CHECK (supports_vision IN (0,1)),
  supports_embeddings INTEGER NOT NULL DEFAULT 0 CHECK (supports_embeddings IN (0,1)),
  supports_streaming INTEGER NOT NULL DEFAULT 1 CHECK (supports_streaming IN (0,1)),
  coding_score REAL NOT NULL DEFAULT 0,
  reasoning_score REAL NOT NULL DEFAULT 0,
  speed_score REAL NOT NULL DEFAULT 0,
  quality_score REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active',
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(provider_id, model_id)
);

CREATE TABLE IF NOT EXISTS model_quotas (
  id TEXT PRIMARY KEY,
  model_id TEXT NOT NULL REFERENCES models(id) ON DELETE CASCADE,
  requests_per_minute INTEGER,
  requests_per_day INTEGER,
  requests_per_month INTEGER,
  tokens_per_minute INTEGER,
  tokens_per_day INTEGER,
  tokens_per_month INTEGER,
  reset_policy TEXT,
  source_url TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS llm_requests (
  id TEXT PRIMARY KEY,
  project_id TEXT,
  provider_id TEXT,
  model_id TEXT,
  task_type TEXT,
  prompt_hash TEXT,
  cache_hit INTEGER NOT NULL DEFAULT 0 CHECK (cache_hit IN (0,1)),
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  latency_ms INTEGER,
  estimated_cost_usd REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  error TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS llm_fallback_events (
  id TEXT PRIMARY KEY,
  request_id TEXT NOT NULL REFERENCES llm_requests(id) ON DELETE CASCADE,
  from_provider_id TEXT,
  from_model_id TEXT,
  to_provider_id TEXT,
  to_model_id TEXT,
  reason TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS automation_runs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  task_type TEXT,
  status TEXT NOT NULL,
  request_budget INTEGER,
  requests_used INTEGER NOT NULL DEFAULT 0,
  started_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT,
  error TEXT
);

CREATE TABLE IF NOT EXISTS webhook_events (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  source TEXT,
  payload_hash TEXT,
  status TEXT NOT NULL DEFAULT 'received',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_llm_requests_created_at ON llm_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_llm_requests_model ON llm_requests(provider_id, model_id);
CREATE INDEX IF NOT EXISTS idx_models_free ON models(is_free, status);
