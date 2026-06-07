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

But the real leverage comes when those pieces become:

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
- Tauri commands
- Hono routes
- FastAPI routes

### 3.2 Agents

Examples:

- PydanticAI agents
- reviewer agents
- documentation agents
- capture agents
- compiler agents
- security agents
- support agents
- sales/package agents

### 3.3 Skills

Examples:

- `capture-site`
- `mirror-api`
- `generate-openapi`
- `generate-mcp`
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

### 3.4 Sub-Agents

Examples:

- Scout researches docs.
- Capture Worker records authorized traffic.
- Normalizer builds mirror rows.
- Compiler generates contracts and tools.
- Reviewer validates generated output.
- Security checks redaction and policy.
- Archivist updates the wiki.
- Operator executes approved commands.

### 3.5 Cronjobs and Timers

Examples:

- nightly repo scan
- daily docs refresh
- hourly model price refresh
- weekly dependency audit
- scheduled capture for authorized targets
- token usage report
- stale mirror detection

### 3.6 Watchdogs and Heartbeats

Examples:

- capture worker heartbeat
- Jetson node heartbeat
- disk pressure watchdog
- failed job watchdog
- stale queue watchdog
- Redis/Qdrant health watchdog
- API gateway health watchdog
- MCP server health watchdog

### 3.7 GitHub Actions

Examples:

- validate OpenAPI specs
- validate YAML registries
- run schema tests
- run generated CLI build
- run generated Python import tests
- run redaction tests
- run docs link checks
- create artifact bundles

### 3.8 Issue Triage and PR Automation

Examples:

- turn failed runs into issues
- label issues by epic
- create implementation tasks
- open PRs from generated changes
- summarize diffs
- review PRs against contracts
- block PRs with missing docs/tests/logging

### 3.9 Applications

Examples:

- local Tauri dashboard
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
        -> Agent Plane
          -> Automation Plane
            -> Product Plane
```

The Automation Plane is where generated capabilities become repeatable systems.

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

## 7. Maximum Leverage Sequence

The best execution order is:

```text
1. Mirror query tools
2. Contract generators
3. MCP wrappers
4. Agent skills
5. Scheduled jobs
6. Watchdogs/heartbeats
7. GitHub issue/PR automations
8. Code review automations
9. Dashboards/apps
10. Monetization deliverables
```

## 8. Definition of Done for an Automation

An automation is not complete unless:

- trigger is defined
- inputs are typed
- outputs are typed
- policy is defined
- logs are emitted
- failure mode is documented
- manual override exists
- tests or dry-run exists
- owner agent is defined
- source mirror/contract is linked
- docs and examples exist

## 9. Final Pipeline Statement

Forge Foundry does not stop at tools.

Forge Foundry turns captures into mirrors, mirrors into contracts, contracts into tools, tools into agents and skills, and agents into scheduled, observable, reviewable automations that can build applications, manage repositories, triage work, review code, generate deliverables, and create monetizable systems.
