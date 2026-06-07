# Forge AI Gateway Architecture

Forge AI Gateway is the local-first model routing, quota optimization, telemetry, cache, RAG, webhook, and automation layer for ForgeOS.

It is designed to sit between every local agent, desktop workflow, CLI, MCP server, API caller, and every model provider.

```txt
Claude Code / Codex / Forge Agents / ForgeWM / MCP / Webhooks / CLI
        ↓
Forge AI Gateway
        ↓
Routing + Quotas + Cache + RAG + Policy + Telemetry
        ↓
OpenAI / Anthropic / Google / Groq / Cerebras / Mistral / OpenRouter / Hugging Face / Ollama / Local vLLM
```

## Core Promises

1. Use the best available free model for the task.
2. Track every request, token, error, fallback, cache hit, and estimated cost.
3. Spend free quotas intentionally through daily automations.
4. Keep local models and cache first for cheap/simple work.
5. Route harder work to the best available model with quota remaining.
6. Expose local API endpoints, CLI commands, systemd timers, and webhook receivers.

## System Components

```txt
Forge AI Gateway
  ├─ Provider Registry
  ├─ Model Matrix
  ├─ Free Model Optimizer
  ├─ Quota Ledger
  ├─ Prompt Cache
  ├─ RAG Injector
  ├─ Fallback Router
  ├─ Usage Telemetry
  ├─ Webhook Router
  ├─ Daily Automation Engine
  └─ SQLite Contract
```

## Local API Surface

Initial endpoint contract:

```txt
GET  /health
GET  /providers
GET  /models
GET  /models/free
GET  /usage/today
GET  /usage/month
GET  /routing/status

POST /chat
POST /complete
POST /code
POST /reason
POST /embed
POST /rerank
POST /tool-call
POST /workflow/run
POST /webhook/:name
```

## Request Flow

```txt
Incoming request
  → assign request_id
  → classify task type
  → check policy
  → check cache
  → inject RAG context
  → check quota
  → rank candidate models
  → call provider
  → fallback if needed
  → log telemetry
  → write cache/eval record
  → return normalized response
```

## Daily Automation Strategy

Forge AI Gateway should not waste free model quota. It should use it deliberately:

```txt
Morning
  - summarize yesterday
  - inspect blocked tasks
  - plan today's useful work

Midday
  - refresh docs/model catalog
  - check provider health
  - improve prompts and runbooks

Evening
  - summarize progress
  - generate issue/PR suggestions
  - compress knowledge base

Night
  - spend leftover free quota on docs, tests, templates, README improvements, evals, and backlog triage
```

## Routing Rule

Before spending quota, every automation must answer:

```txt
Is this task useful?
Can a local model do it?
Is there a cached answer?
Which free model is best?
How much quota remains?
What fallback should be used?
How will the result be evaluated?
Where will the artifact be stored?
```

## Implementation Phases

### Phase 1 — Contract and local scaffold

- SQLite schema
- Provider config
- Routing config
- Automation config
- Installer script
- systemd service/timers
- local CLI placeholder

### Phase 2 — Gateway API

- Hono/Node or Go HTTP server
- `/health`, `/models`, `/usage`, `/chat`
- SQLite ledger writes
- provider registry loading

### Phase 3 — AI SDK middleware

- `wrapLanguageModel`
- cache middleware
- RAG middleware
- telemetry metadata
- fallback routing

### Phase 4 — Dashboard

- Free Model Matrix
- usage today/month
- quota remaining
- fallback events
- provider health
- daily automation status

### Phase 5 — Agentic daily factory

- scheduled useful tasks
- model evals
- docs refresh
- GitHub issue triage
- prompt/runbook improvement
- local KB compression

## Related Files

```txt
schemas/ai-gateway/schema.sql
configs/ai-gateway/providers.yaml
configs/ai-gateway/routing.yaml
configs/ai-gateway/automations.yaml
scripts/install-ai-gateway.sh
scripts/forge-ai-gateway.sh
systemd/user/forge-ai-gateway.service
systemd/user/forge-provider-health.timer
systemd/user/forge-quota-check.timer
systemd/user/forge-daily-automation.timer
```
