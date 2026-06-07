# Forge Monorepo + LLM Wiki Architecture

This document proposes the larger project organization system that ForgeOS should bootstrap.

The goal is to create a monorepo and LLM wiki system for building, tracking, compiling, documenting, and observing all Forge projects.

## One-sentence vision

Build a local-first project operating system where every repo, agent, model call, tool call, compiler run, document, task, decision, and artifact is tracked, linked, searchable, and reusable by humans and agents.

## Recommended monorepo name

Suggested names:

- `forge-labs`
- `forge-stack`
- `forge-command-center`
- `forge-foundry`
- `forge-monorepo`
- `agentic-forge`

Recommended:

```text
forge-foundry
```

Reason: it describes the system as the place where products, tools, agents, docs, and automation pipelines are forged.

## Top-level monorepo structure

```text
forge-foundry/
  README.md
  PROJECT.md
  ROADMAP.md
  ARCHITECTURE.md
  STACK.md
  OBSERVABILITY.md
  SECURITY.md
  AGENTS.md
  SKILLS.md
  WORKFLOWS.md

  apps/
    command-center/          # Tauri or web dashboard
    forge-studio/            # AI IDE / project builder
    forge-symphony/          # orchestration dashboard
    docs-site/               # public/private docs site

  packages/
    ui/                      # shared components
    config/                  # shared tsconfig/eslint/tailwind/etc
    contracts/               # JSON Schema, Zod, Pydantic contracts
    sdk/                     # generated SDKs
    prompts/                 # prompt packs
    skills/                  # SKILL.md packages
    evals/                   # eval harnesses

  services/
    gateway/                 # provider/model routing proxy
    observability/           # trace/log/cost ingestion service
    wiki-api/                # local LLM wiki API
    compiler-api/            # spec/doc/code generation API
    webhook-gateway/         # GitHub/n8n/local webhook intake

  tools/
    forge-cli/               # Cobra/Go or TS CLI
    forge-tui/               # terminal command center
    agentic-press/           # compiler/tool factory
    hf-press/                # Hugging Face/model discovery
    gh-press/                # GitHub repo/issue/PR tooling
    openapi-press/           # OpenAPI/HAR -> CLI/MCP/SDK

  agents/
    scribe/
    scout/
    courier/
    artisan/
    watcher/
    archivist/
    analyst/
    operator/
    security-engineer/
    devops-engineer/
    web-app-builder/
    ux-ui-architect/
    runtime-engineer/

  workflows/
    install/
    repo-scan/
    docs-generate/
    openapi-compile/
    skill-generate/
    release/
    security-audit/

  contracts/
    schemas/
    openapi/
    asyncapi/
    arazzo/

  observability/
    schema.sql
    dashboards/
    reports/
    fixtures/

  wiki/
    index.md
    projects/
    architecture/
    decisions/
    agents/
    skills/
    workflows/
    models/
    providers/
    glossary/
    runbooks/
    raw/
    generated/

  raw/
    inbox/
    normalized/
    classified/
    archived/

  generated/
    docs/
    issues/
    specs/
    sdks/
    clis/
    mcp/
    skills/

  .github/
    workflows/
    ISSUE_TEMPLATE/
```

## LLM wiki mission

The LLM wiki is not just markdown notes. It is the project memory layer.

It should answer:

- What projects exist?
- What is each project for?
- What files matter?
- What agents own what?
- What models/providers are available?
- What tools and workflows exist?
- What was decided and why?
- What changed recently?
- What needs to happen next?
- What generated this artifact?
- What model/tool/compiler produced this output?

## LLM wiki layers

```text
wiki/raw/          unprocessed notes, chats, imports
wiki/generated/    AI-generated pages awaiting review
wiki/projects/     one page per project
wiki/architecture/ system diagrams and explanations
wiki/decisions/    ADR-style decision records
wiki/agents/       agent identities, tools, policies
wiki/skills/       skill docs and SKILL.md references
wiki/workflows/    repeatable workflow documentation
wiki/models/       model/provider routing knowledge
wiki/runbooks/     how-to operational docs
wiki/glossary/     shared terminology
```

## Wiki database model

The ForgeOS observability schema already includes:

```text
wiki_pages
wiki_edges
artifacts
events
compiler_runs
model_calls
tool_calls
agent_runs
```

The wiki should store page bodies on disk and metadata/edges in SQLite.

Each page should have frontmatter:

```yaml
---
id: wiki.project.forge-os
title: ForgeOS
kind: project
project: forge-os
tags: [os, workstation, command-center]
source_artifacts: []
last_reviewed: null
owner_agent: archivist
status: draft
---
```

## Compiler pipeline

The monorepo needs a compiler layer called Agentic Press.

Pipeline:

```text
raw input
  -> normalize
  -> classify
  -> extract facts
  -> validate schema
  -> generate wiki page
  -> generate docs/specs/tasks
  -> record compiler run
  -> record artifacts
  -> update graph edges
```

Inputs:

- repo scan
- README files
- raw chat exports
- docs pages
- OpenAPI specs
- HAR captures
- GitHub issues
- terminal logs
- model call logs
- tool call logs

Outputs:

- wiki pages
- task YAML
- GitHub issues
- OpenAPI specs
- AsyncAPI specs
- Arazzo workflows
- SKILL.md packs
- CLI scaffolds
- MCP wrappers
- SDKs

## Agent roles in monorepo

| Agent | Purpose |
|---|---|
| Scribe | Writes docs, summaries, changelogs |
| Scout | Researches tools, packages, docs, repos |
| Courier | Routes messages, webhooks, notifications |
| Artisan | UI, visual design, component polish |
| Watcher | Logs, heartbeats, alerts, observability |
| Archivist | Wiki, memory, indexing, retrieval |
| Analyst | Compares options, reads metrics, scores outputs |
| Operator | Executes approved local commands and install flows |
| Security Engineer | Hardening, policy, scanners, audits |
| DevOps Engineer | CI/CD, deployment, infrastructure |
| Runtime Engineer | Agents, queues, services, event bus |
| Web App Builder | Full-stack product implementation |
| UX/UI Architect | Product flows, pages, layouts, design system |

## Observability requirements

Every meaningful action should write:

1. a JSONL event
2. a SQLite row
3. an artifact if the body is large
4. a wiki edge if it creates knowledge

Minimum tracked dimensions:

- timestamp
- project
- agent
- run id
- trace id
- model/provider
- tool name
- input tokens
- output tokens
- latency
- estimated cost
- command/status/exit code
- source artifact
- output artifact

## Local-first stack

Start with:

- SQLite
- JSONL
- Markdown
- YAML
- Git history
- ripgrep/fd/fzf
- Go CLI/TUI
- Python compiler workers

Add later:

- embeddings
- vector search
- graph database if needed
- OpenTelemetry
- Langfuse/LangSmith-style tracing
- Prometheus/Grafana
- NATS
- Tauri dashboard

## Package manager recommendation

For a mixed Go/Rust/TypeScript/Python monorepo:

- `pnpm` for JS/TS workspaces
- `turbo` or `nx` for task orchestration
- Cargo workspace for Rust
- Go workspace for Go tools
- `uv` for Python packages
- `just` for top-level commands

## First implementation phases

### Phase 0: Spine

- Create monorepo skeleton
- Add observability schema
- Add wiki folder
- Add event writer
- Add one compiler command
- Generate one wiki page from one raw note

### Phase 1: Project registry

- `projects.yaml`
- project pages
- repo scanner
- README importer
- architecture page generator

### Phase 2: Agent registry

- `agents.yaml`
- agent wiki pages
- agent policies
- agent run logging

### Phase 3: Tool/compiler registry

- `tools.yaml`
- compiler run logs
- OpenAPI/HAR import
- generated CLI/MCP stubs

### Phase 4: LLM trace middleware

- model call logging
- token/cost registry
- provider routing
- request/response artifact capture with redaction

### Phase 5: Visual command center

- Tauri or web dashboard
- wiki browser
- trace viewer
- cost dashboard
- run graph
- project map

## Key rule

The monorepo should not depend on chat memory.

The repo, wiki, SQLite database, JSONL logs, generated docs, and git history must be enough for a fresh agent session to understand the current state.
