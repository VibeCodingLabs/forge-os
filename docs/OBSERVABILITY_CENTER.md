# ForgeOS Observability Center

The ForgeOS Observability Center is the local-first telemetry layer for the agent workstation.

Its job is to track every meaningful agent/runtime action:

- agent runs
- model calls in/out
- tool calls
- shell commands
- compiler/generator runs
- artifacts
- errors
- audit events
- wiki pages
- wiki graph edges

It is not a cloud dependency. It starts as a local SQLite + JSONL system under:

```text
~/.forge-os/observability/forge-observability.db
~/.forge-os/logs/*.jsonl
~/.forge-os/artifacts/
~/.forge-os/wiki/
```

## Install

```bash
bash scripts/install-observability-center.sh
```

The full command center installer also runs it automatically:

```bash
bash scripts/install-full-command-center.sh
```

## Core database tables

The schema lives at:

```text
observability/schema.sql
```

Main tables:

| Table | Purpose |
|---|---|
| `events` | General event ledger |
| `agent_runs` | Agent/session/task attempts |
| `model_calls` | Provider/model calls, token counts, latency, cost estimates |
| `tool_calls` | CLI/MCP/API/browser/shell tool calls |
| `compiler_runs` | Code/spec/doc/compiler/generator runs |
| `artifacts` | Content-addressed outputs and captured files |
| `wiki_pages` | Local LLM wiki pages |
| `wiki_edges` | Knowledge graph edges between wiki pages |

## Installed helper commands

### `forge-event`

Record a generic event:

```bash
forge-event agent.started "Scout started repo scan"
```

Optional environment:

```bash
FORGE_PROJECT=forge-os \
FORGE_AGENT=scout \
FORGE_RUN_ID=run_001 \
forge-event agent.started "Scout started repo scan"
```

### `forge-model-call`

Record a model call summary:

```bash
forge-model-call openai gpt-4.1 route-main 1200 450 1800
```

Arguments:

```text
provider model route input_tokens output_tokens latency_ms
```

### `forge-tool-call`

Record a tool call summary:

```bash
FORGE_COMMAND="git status --short" forge-tool-call git ok 0
```

### `forge-compile-log`

Record a compiler/generator run:

```bash
forge-compile-log openapi-generator contracts/api.yaml generated/sdk
```

### `forge-observe`

Show a quick local dashboard:

```bash
forge-observe
```

It prints recent events, model cost summary, and recent tool calls.

## Event model

Everything should eventually emit one of these event families:

```text
agent.run.started
agent.run.completed
agent.run.failed
model.call.started
model.call.completed
model.call.failed
tool.call.started
tool.call.completed
tool.call.failed
compiler.run.started
compiler.run.completed
compiler.run.failed
artifact.created
wiki.page.created
wiki.edge.created
security.warning
policy.denied
approval.requested
approval.granted
approval.rejected
```

## Future cloud/advanced integrations

The local schema is designed to be compatible with later integrations:

- OpenTelemetry traces
- Langfuse / LangSmith-style LLM traces
- Prometheus/Grafana metrics
- NATS event bus
- Vector logs
- local Tauri dashboard
- web dashboard in Forge Symphony

The rule is:

> local SQLite + JSONL first, cloud observability optional later.

## What still needs to be built

- automatic shell wrapper for every command
- MCP middleware logger
- OpenAI/Anthropic/Vercel AI SDK proxy logger
- browser automation event bridge
- GitHub webhook event bridge
- Tauri visual dashboard
- model price registry
- artifact hashing helper
- wiki page generator
- wiki graph builder
- embeddings/vector search lane
