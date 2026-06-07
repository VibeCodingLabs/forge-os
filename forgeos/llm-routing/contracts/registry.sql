-- ForgeOS LLM registry schema contract
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS providers (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  homepage_url TEXT,
  docs_url TEXT,
  connection_modes_json TEXT NOT NULL DEFAULT '[]',
  ai_sdk_package TEXT,
  openai_compatible INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS models (
  id TEXT PRIMARY KEY,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  provider_model_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'unknown',
  is_free_tier INTEGER NOT NULL DEFAULT 0,
  is_open_weights INTEGER NOT NULL DEFAULT 0,
  input_modalities_json TEXT NOT NULL DEFAULT '[]',
  output_modalities_json TEXT NOT NULL DEFAULT '[]',
  capabilities_json TEXT NOT NULL DEFAULT '[]',
  parameter_count_text TEXT,
  parameter_count_billions REAL,
  context_window_tokens INTEGER,
  max_output_tokens INTEGER,
  supports_streaming INTEGER NOT NULL DEFAULT 0,
  supports_tools INTEGER NOT NULL DEFAULT 0,
  supports_structured_output INTEGER NOT NULL DEFAULT 0,
  supports_json_mode INTEGER NOT NULL DEFAULT 0,
  supports_reasoning_tokens INTEGER NOT NULL DEFAULT 0,
  supports_cached_input_tokens INTEGER NOT NULL DEFAULT 0,
  model_card_url TEXT,
  docs_url TEXT,
  discovered_at TEXT,
  last_verified_at TEXT,
  verification_source TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(provider_id, provider_model_id)
);

CREATE TABLE IF NOT EXISTS free_tier_limits (
  id TEXT PRIMARY KEY,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  model_id TEXT REFERENCES models(id) ON DELETE CASCADE,
  limit_scope TEXT NOT NULL,
  requests_per_minute INTEGER,
  requests_per_day INTEGER,
  requests_per_month INTEGER,
  tokens_per_minute INTEGER,
  tokens_per_day INTEGER,
  tokens_per_month INTEGER,
  concurrent_requests INTEGER,
  reset_timezone TEXT DEFAULT 'UTC',
  notes TEXT,
  source_url TEXT,
  last_verified_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
