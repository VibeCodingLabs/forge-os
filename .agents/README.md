# ForgeOS Agent Workspaces

The `.agents` directory is the local operating structure for ForgeOS agent orchestration.

Each agent owns a dedicated workspace with the same internal shape so tools, installers, dashboards, and future schedulers can discover capabilities consistently.

## Agents

- `scribe` - documentation, READMEs, runbooks, changelogs, and operator notes
- `scout` - research, package discovery, docs checks, version checks, and advisory review
- `courier` - notifications, summaries, handoffs, issue updates, and release messaging
- `artisan` - terminal UX, TUI flows, themes, visuals, layouts, and interaction polish
- `watcher` - observability, logs, timers, service health, alerts, and posture checks
- `archivist` - indexes, manifests, inventory, history, boundaries, and records
- `analyst` - evals, costs, benchmarks, traces, metrics, and tradeoff analysis
- `operator` - approvals, queues, orchestration, task routing, and final action gates

## Standard agent directory contract

Each agent directory should include:

- `AGENT.md` - human-readable identity, mission, rules, inputs, outputs, and boundaries
- `manifest.yaml` - machine-readable metadata for future CLI/TUI discovery
- `workflows/` - repeatable procedures the agent can run or coordinate
- `skills/` - reusable capability modules following the SKILL.md direction
- `prompts/` - prompt templates, system fragments, checklists, and instruction blocks
- `policies/` - permissions, refusal boundaries, safety gates, and approval requirements
- `evals/` - tests, rubrics, scorecards, benchmarks, and acceptance criteria
- `tools/` - allowed tool notes, wrappers, command references, and integration contracts
- `templates/` - reusable markdown, config, report, issue, PR, and changelog templates
- `memory/` - public-safe state notes, decisions, preferences, and handoff summaries

## Public repo rule

This directory is for safe scaffolding only. Keep private operator overlays, credentials, customer data, private evidence, access material, and local runtime logs outside the public repository.

## Future extensions

Recommended next directories once the runtime grows:

- `handoffs/` for agent-to-agent transfer notes
- `runbooks/` for operational playbooks
- `schemas/` for JSON/YAML contracts
- `queues/` for local task inbox/outbox files
- `reports/` for generated public-safe summaries
- `fixtures/` for safe sample data
- `adapters/` for CLI, API, and model-provider connectors
