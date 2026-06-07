# Forge Foundry Architecture

## 1. Architecture Summary

Forge Foundry is a capture-to-contract system.

It is composed of these planes:

1. Host Plane
2. Capture Plane
3. Raw Artifact Plane
4. Mirror Plane
5. Compiler Plane
6. Tool Plane
7. Agent Plane
8. Observability Plane
9. LLM Wiki Plane
10. Monetization Plane

Each plane has a clear responsibility and should be independently testable.

```text
ForgeOS / Jetson / Workstation
  -> Capture Workers
  -> Raw Artifacts
  -> SQLite Mirrors
  -> Contract Compilers
  -> CLI / REST / MCP Tools
  -> PydanticAI Agents
  -> Observability + Wiki
  -> Products / Client Packages
```

## 2. Host Plane

### Purpose

The Host Plane installs and manages the local machine environment.

### Owned By

ForgeOS.

### Responsibilities

- Debian workstation setup
- Jetson Orin Nano worker setup
- River desktop command center
- terminal/TUI command center
- systemd timers
- local logs
- sandboxing
- firewall and hardening
- observability database
- local directories and state

### Key Paths

```text
~/.forge-os/
  observability/
  logs/
  artifacts/
  wiki/
  state/
  sandboxes/
  worktrees/
```

## 3. Capture Plane

### Purpose

Capture authorized behavior from URLs, web apps, API docs, browser workflows, and repositories.

### Workers

- Playwright worker
- Chromium worker
- mitmdump worker
- HAR import worker
- docs crawler
- repo scanner
- XHR/API flow parser

### Official Tooling Basis

Mitmproxy supports addon scripts that hook traffic events such as request/response, and `mitmdump -s` can run those addons headlessly. This makes it a strong base for a Jetson/worker capture service.

mitmproxy2swagger can convert mitmproxy captures and HAR exports into OpenAPI descriptions, using a review-oriented process where path templates are identified and then rerun to generate endpoint definitions.

### Capture Inputs

```text
URL
HAR file
mitmproxy flow
OpenAPI spec
Swagger spec
Postman collection
curl command
GitHub repository
docs site
llms.txt
browser workflow
manual API notes
```

### Capture Outputs

```text
raw/captures/*.mitm
raw/har/*.har
raw/html/*.html
raw/screenshots/*.png
raw/responses/*.json
raw/headers/*.json
raw/manifests/*.json
```

## 4. Raw Artifact Plane

### Purpose

Preserve raw evidence and captured material before normalization.

### Rules

- Raw capture files are sensitive.
- Raw files are append-only by default.
- Raw files should be redacted before promotion.
- Large raw bodies should live on disk, not inside SQLite.
- SQLite should store metadata and artifact references.

### Raw Artifact Types

- HAR
- mitmproxy flow
- screenshots
- HTML snapshots
- JSON responses
- request bodies
- response bodies
- headers
- cookies, only if redacted or secured
- docs pages
- repo scans

## 5. Mirror Plane

### Purpose

Convert raw artifacts into structured local mirrors.

### Primary Store

SQLite.

### Why SQLite First

- simple
- local-first
- portable
- queryable by agents
- easy to back up
- easy to inspect
- no required daemon
- works on workstation and Jetson

### Mirror Entities

```text
sites
captures
requests
responses
endpoints
parameters
headers
schemas
examples
workflows
artifacts
jobs
```

### Mirror Rules

1. Every endpoint must link to source capture artifacts.
2. Every inferred schema must link to examples.
3. Every generated contract must link to mirror rows.
4. Every live recapture must produce a new capture version.
5. Agents query mirrors before raw artifacts.

## 6. Compiler Plane

### Purpose

Compile mirrors into contracts, tools, docs, SDKs, and wiki pages.

### Compilers

- HAR/flow to endpoint catalog
- endpoint catalog to OpenAPI 3.1
- OpenAPI to Zod schemas
- OpenAPI to Pydantic models
- OpenAPI to Cobra commands
- OpenAPI to FastMCP tools
- OpenAPI to Arazzo workflows
- mirror to LLM wiki pages
- mirror to monetization package

### Compiler Outputs

```text
generated/openapi/*.yaml
generated/arazzo/*.yaml
generated/zod/*
generated/pydantic/*
generated/cobra/*
generated/mcp/*
generated/docs/*
generated/wiki/*
```

### Compiler Observability

Every compiler run should create:

1. `compiler_runs` SQLite row
2. `compiler-runs.jsonl` event
3. output artifact record
4. validation result
5. summary note

## 7. Tool Plane

### Purpose

Expose compiled knowledge as deterministic tools.

### Tool Types

- Cobra/Go CLI
- REST API
- MCP server
- FastMCP tools
- Python SDK
- TypeScript SDK
- shell scripts
- Tauri commands
- Hono routes

### Tool Rule

A tool is valid only if it has:

- name
- description
- input schema
- output schema
- source mirror reference
- error model
- tests or examples
- observability logging

## 8. Agent Plane

### Purpose

Run agents that use mirrors and tools to perform work.

### Agent Framework

PydanticAI is the preferred Python agent layer because it supports typed tool usage and production agent patterns.

### MCP Layer

FastMCP can wrap Python functions as MCP tools/resources/prompts, making it a good fit for exposing SQLite mirrors and generated API tools to agents.

### Agent Roles

```text
Scribe       docs and summaries
Scout        research and discovery
Archivist    wiki and memory
Analyst      comparisons and scoring
Operator     approved execution
Watcher      observability and alerts
Security     policy and hardening
Compiler     contract and tool generation
```

### Agent Rule Order

Agents must use this order:

1. SQLite mirror
2. generated OpenAPI/Arazzo contract
3. generated CLI/MCP/REST tool
4. LLM wiki
5. raw artifact
6. live capture only if authorized and approved

## 9. Observability Plane

### Purpose

Track every meaningful action.

### Stores

```text
~/.forge-os/observability/forge-observability.db
~/.forge-os/logs/events.jsonl
~/.forge-os/logs/model-calls.jsonl
~/.forge-os/logs/tool-calls.jsonl
~/.forge-os/logs/compiler-runs.jsonl
~/.forge-os/logs/agent-runs.jsonl
```

### Event Families

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
policy.denied
approval.requested
approval.granted
```

## 10. LLM Wiki Plane

### Purpose

Make the system understandable across context resets.

### Wiki Outputs

- project pages
- endpoint pages
- capture summaries
- workflow pages
- architecture notes
- task pages
- decision records
- monetization package pages

### Wiki Rules

- Wiki pages should have YAML frontmatter.
- Pages should link to source artifacts.
- Generated pages should be reviewed before becoming canonical.
- Wiki metadata should be indexed in SQLite.
- Wiki edges should describe relationships between projects, APIs, workflows, tasks, and agents.

## 11. Monetization Plane

### Purpose

Package technical outputs into client-ready offers.

### Product Packages

- API Map Package
- OpenAPI Rescue Package
- Internal Tool Wrapper Package
- MCP Tool Pack
- Automation Audit Package
- Local Mirror Token Savings Package
- Browser Workflow Conversion Package
- Agent Observability Package

## 12. Deployment Shape

### Local Workstation

ForgeOS installs local CLI/TUI, desktop command center, observability, and agent runtime.

### Jetson Node

The Jetson runs 24/7 capture and compiler jobs for authorized targets.

### Cloud Optional

Cloud services can later host dashboards, webhooks, and customer-facing APIs, but v1 should work locally.

## 13. Docker Compose Services

Recommended service set:

```text
api-gateway       Hono REST API, Zod contracts, OpenAPI docs
agent-python      FastAPI/PydanticAI agent endpoint
capture-worker    Playwright/mitmdump/HAR capture worker
compiler          mirror-to-contract/tool compiler
mcp-server        FastMCP tools over SQLite mirror
redis             queue/cache
qdrant            semantic search/RAG
```

## 14. Critical Architecture Decision

Redis and Qdrant are not the source of truth.

SQLite and artifacts are the source of truth.

Redis is for queue/cache.
Qdrant is for semantic retrieval.
JSONL is for append-only event logs.
Markdown is for human review.
Git is for history.
