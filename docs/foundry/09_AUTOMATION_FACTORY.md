# Forge Foundry Automation Factory

## 1. Corrected Pipeline

The core pipeline is not merely:

```text
capture -> mirror -> contract -> tools
```

The full pipeline is:

```text
capture
  -> mirror
  -> contract
  -> tools
  -> MCPs
  -> Python scripts
  -> Go scripts
  -> Rust sidecars
  -> Tauri v2 GUI
  -> agents
  -> skills
  -> sub-agents
  -> cronjobs
  -> watchdogs
  -> heartbeats
  -> GitHub Actions
  -> issue triaging
  -> pull requests
  -> code review
  -> APIs
  -> code
  -> commands
  -> workflows
  -> applications
  -> automations
  -> products
```

## 2. Why This Matters

The generated tool is not the final product.

The final product is an automation surface that can execute useful work repeatedly, safely, observably, and cheaply.

A generated OpenAPI spec is useful.
A generated CLI is useful.
A generated MCP server is useful.
A generated Python script is useful.
A generated Go command is useful.
A generated Rust sidecar is useful.
A generated Tauri v2 GUI is useful.

But the real leverage comes when those pieces become:

- MCP servers and tools
- Python automation scripts
- Go CLIs and daemon utilities
- Rust sidecars controlled by Tauri
- Tauri v2 desktop dashboards
- agent skills
- scheduled jobs
- PR bots
- issue triage bots
- internal APIs
- dashboards
- watchdogs
- workflows
- client-ready apps
- code generators
- monetizable automation packages

## 3. Automation Output Classes

### 3.1 Tools

Examples:

- Cobra CLI commands
- REST API wrappers
- MCP tools
- SDK functions
- shell commands
- Python scripts
- Go scripts
- Rust sidecars
- Tauri commands
- Hono routes
- FastAPI routes

### 3.2 MCPs

Examples:

- FastMCP mirror-query server
- MCP resources over artifacts
- MCP prompts for workflow execution
- MCP tools for generated API wrappers
- MCP tools for wiki lookup
- MCP tools for observability queries
- MCP tools for capture job submission
- MCP tools for GitHub issue/PR automation

Each MCP should include:

- server name
- transport mode
- tool list
- resource list
- prompt list
- input schemas
- output schemas
- policy gates
- logging hooks
- example calls
- tests

### 3.3 Python Scripts

Examples:

- HAR importer
- mitmproxy flow parser
- schema inference worker
- Pydantic model generator
- wiki page generator
- capture normalizer
- redaction scanner
- embedding/index worker
- PydanticAI agent runner
- report generator

Python scripts are best for:

- data parsing
- AI/LLM integrations
- Pydantic validation
- quick workers
- notebooks/prototyping
- compiler glue

### 3.4 Go Scripts and CLIs

Examples:

- Cobra command tree
- mirror query CLI
- capture job CLI
- validation CLI
- local API server
- worker supervisor
- log tailer
- GitHub issue triage CLI
- generated API command wrapper

Go is best for:

- single-binary tools
- fast CLIs
- long-running lightweight daemons
- cross-platform operators
- strict operational tooling

### 3.5 Rust Sidecars

Examples:

- secure command runner
- sandbox launcher
- file watcher
- high-performance log ingester
- local SQLite service
- Tauri-managed worker process
- browser session supervisor
- system telemetry collector

Rust sidecars are best for:

- process control
- system integration
- performance-sensitive workers
- safer long-running local services
- Tauri backend extensions

### 3.6 Tauri v2 GUI

Examples:

- local command center dashboard
- capture job manager
- endpoint/mirror browser
- OpenAPI/Arazzo viewer
- tool/MCP registry viewer
- agent run viewer
- observability dashboard
- wiki browser
- artifact browser
- generated app launcher
- settings/policy manager

The Tauri v2 GUI should not do heavy work directly.

It should orchestrate:

- Rust commands
- Rust sidecars
- Python workers
- Go CLIs
- MCP servers
- REST APIs
- SQLite queries
- systemd timers
- logs and artifacts

### 3.7 Agents

Examples:

- PydanticAI agents
- reviewer agents
- documentation agents
- capture agents
- compiler agents
- security agents
- support agents
- sales/package agents

### 3.8 Skills

Examples:

- `capture-site`
- `mirror-api`
- `generate-openapi`
- `generate-mcp`
- `generate-python-script`
- `generate-go-cli`
- `generate-rust-sidecar`
- `generate-tauri-panel`
- `triage-issues`
- `review-pr`
- `summarize-run`
- `package-deliverable`

Each skill should include:

- name
- description
- invocation phrases
- slash command
- required tools
- inputs
- outputs
- safety rules
- gotchas
- examples
- acceptance criteria

### 3.9 Sub-Agents

Examples:

- Scout researches docs.
- Capture Worker records authorized traffic.
- Normalizer builds mirror rows.
- Compiler generates contracts and tools.
- Reviewer validates generated output.
- Security checks redaction and policy.
- Archivist updates the wiki.
- Operator executes approved commands.
- Sidecar Engineer builds Rust sidecars.
- UI Engineer builds Tauri v2 panels.
- CLI Engineer builds Cobra/Go commands.
- Python Worker Engineer builds Pydantic/Python workers.

### 3.10 Cronjobs and Timers

Examples:

- nightly repo scan
- daily docs refresh
- hourly model price refresh
- weekly dependency audit
- scheduled capture for authorized targets
- token usage report
- stale mirror detection

### 3.11 Watchdogs and Heartbeats

Examples:

- capture worker heartbeat
- Jetson node heartbeat
- disk pressure watchdog
- failed job watchdog
- stale queue watchdog
- Redis/Qdrant health watchdog
- API gateway health watchdog
- MCP server health watchdog
- Rust sidecar health watchdog
- Tauri app health watchdog

### 3.12 GitHub Actions

Examples:

- validate OpenAPI specs
- validate YAML registries
- run schema tests
- run generated CLI build
- run generated Python import tests
- run generated Rust sidecar build
- run generated Tauri frontend typecheck
- run redaction tests
- run docs link checks
- create artifact bundles

### 3.13 Issue Triage and PR Automation

Examples:

- turn failed runs into issues
- label issues by epic
- create implementation tasks
- open PRs from generated changes
- summarize diffs
- review PRs against contracts
- block PRs with missing docs/tests/logging

### 3.14 Applications

Examples:

- local Tauri v2 dashboard
- web dashboard
- internal API explorer
- workflow builder
- capture job manager
- artifact browser
- LLM wiki browser
- monetization package generator

## 4. Automation Factory Architecture

```text
Capture Plane
  -> Mirror Plane
    -> Contract Plane
      -> Tool Plane
        -> Script / MCP / Sidecar Plane
          -> Agent Plane
            -> Automation Plane
              -> GUI / Application Plane
                -> Product Plane
```

The Automation Plane is where generated capabilities become repeatable systems.

The Script / MCP / Sidecar Plane is where generated contracts become executable local capabilities.

The GUI / Application Plane is where Tauri v2 and web dashboards expose those capabilities to humans.

## 5. Automation Manifest

Every generated automation should have a manifest:

```yaml
id: automation.example.issue-triage
name: Issue Triage Automation
kind: github_action
status: draft
source_contract: generated/openapi/example.openapi.yaml
source_mirror: mirrors/example.sqlite
owner_agent: watcher
runtime_targets:
  - mcp
  - python_script
  - go_cli
  - rust_sidecar
  - tauri_v2_gui
triggers:
  - github.issue.opened
inputs:
  - issue_title
  - issue_body
outputs:
  - labels
  - priority
  - suggested_owner
  - summary_comment
observability:
  events:
    - automation.started
    - automation.completed
    - automation.failed
policies:
  - RULE-MIRROR-001
  - RULE-OBS-001
  - RULE-AGENT-001
approval_required: false
```

## 6. Automation Rule

Generated automations must be:

- observable
- documented
- policy-gated
- reversible when possible
- testable
- linked to source contracts
- linked to source mirrors
- linked to owner agents
- connected to acceptance criteria
- exposed through the appropriate runtime target
- compatible with the Tauri v2 command center when GUI control is needed

## 7. Maximum Leverage Sequence

The best execution order is:

```text
1. Mirror query tools
2. Contract generators
3. MCP wrappers
4. Python worker scripts
5. Go CLI commands
6. Rust sidecars
7. Tauri v2 GUI panels
8. Agent skills
9. Scheduled jobs
10. Watchdogs/heartbeats
11. GitHub issue/PR automations
12. Code review automations
13. Dashboards/apps
14. Monetization deliverables
```

## 8. Definition of Done for an Automation

An automation is not complete unless:

- trigger is defined
- inputs are typed
- outputs are typed
- policy is defined
- runtime target is declared
- logs are emitted
- failure mode is documented
- manual override exists
- tests or dry-run exists
- owner agent is defined
- source mirror/contract is linked
- docs and examples exist
- if GUI-controlled, Tauri v2 integration notes exist
- if sidecar-backed, process lifecycle and health checks exist

## 9. Runtime Target Decision Matrix

| Runtime Target | Use For | Avoid For |
|---|---|---|
| MCP | Agent/tool interoperability, mirror queries, generated API tools | Heavy local process control |
| Python script | parsing, AI workers, Pydantic, compilers, reports | tiny static binaries or privileged process control |
| Go script/CLI | Cobra commands, validation, local servers, ops tools | complex UI or deep desktop integration |
| Rust sidecar | secure process control, watchers, performance, Tauri backend workers | fast prototyping or large ML libraries |
| Tauri v2 GUI | human command center, dashboards, settings, approvals | direct heavy scraping/capture work |

## 10. Final Pipeline Statement

Forge Foundry does not stop at tools.

Forge Foundry turns captures into mirrors, mirrors into contracts, contracts into MCPs, scripts, CLIs, sidecars, GUIs, tools, agents, skills, scheduled jobs, review systems, applications, and monetizable automation products.
