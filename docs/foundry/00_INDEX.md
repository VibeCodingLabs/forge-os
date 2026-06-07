# Forge Foundry Documentation Index

This folder defines the full Capture-to-Contract / Observability / LLM Wiki vision that ForgeOS should bootstrap and Forge Foundry should implement.

## Document Map

| File | Purpose |
|---|---|
| `01_VISION.md` | North-star vision, mission, product thesis, operating principles, target users, monetization posture. |
| `02_ARCHITECTURE.md` | End-to-end architecture for Jetson capture workers, SQLite mirrors, contract compilers, REST/MCP/CLI wrappers, observability, and wiki. |
| `03_ROADMAP.md` | Waves, phases, milestones, slices, acceptance gates, and rollout order. |
| `04_EPICS_TASK_GRAPH.md` | Exhaustive implementation task graph with epics, tasks, sub-tasks, dependencies, and Definition of Done. |
| `05_PROMPT_CHAINS.md` | Prompt chains for research, capture planning, schema generation, compiler runs, codegen, reviews, wiki updates, monetization packaging. |
| `06_RULES_GOTCHAS_PITFALLS.md` | Hard rules, gotchas, pitfalls, safety boundaries, compliance notes, and architecture constraints. |
| `07_BACKLOG_TODOS.md` | Prioritized TODO list grouped by P0/P1/P2/P3. |
| `08_MACHINE_READABLE_REGISTRY.md` | Explanation of YAML/JSON control files for agents and automation. |

## Machine-Readable Companions

| File | Purpose |
|---|---|
| `config/foundry/epics.yaml` | Canonical epic/milestone/task registry. |
| `config/foundry/prompt-chains.yaml` | Canonical prompt-chain registry. |
| `config/foundry/rules.yaml` | Policy/rules registry for agents, capture, mirrors, tools, and observability. |

## Core Thesis

Forge Foundry is a local-first project intelligence factory:

```text
authorized URL / app / repo / docs / API traffic
  -> capture worker
  -> raw artifacts
  -> normalizer
  -> SQLite mirror
  -> contract compiler
  -> OpenAPI / Arazzo / Zod / Pydantic
  -> Cobra CLI / REST API / MCP server
  -> PydanticAI agents query local mirrors first
  -> observability + LLM wiki update
  -> monetizable integration package
```

## One Rule

Agents should not burn context reading the same web pages, docs, or API traces repeatedly.

They should use this order:

1. SQLite mirror
2. Generated contract
3. Generated CLI/MCP tool
4. Local LLM wiki
5. Raw artifact
6. Live capture only when authorized, missing, stale, and approved
