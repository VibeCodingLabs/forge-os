# Forge Foundry Epics and Task Graph

## 1. Epic Overview

| Epic | Name | Outcome |
|---|---|---|
| E00 | Governance + Repo Standards | Clear docs, standards, schemas, issue/task conventions. |
| E01 | ForgeOS Host Runtime | Fresh machine can install command center reliably. |
| E02 | Observability Center | Every meaningful event can be logged locally. |
| E03 | Capture Worker Runtime | Authorized URLs/workflows can be captured. |
| E04 | SQLite Mirror | Captures become structured queryable data. |
| E05 | Contract Compiler | Mirrors become OpenAPI/Zod/Pydantic/Arazzo. |
| E06 | Tool Generator | Contracts become Cobra/REST/MCP/SDK tools. |
| E07 | Agent Runtime | PydanticAI agents use mirror-first tools. |
| E08 | LLM Wiki | Project knowledge becomes durable and searchable. |
| E09 | Jetson 24/7 Node | Jetson runs capture/compile jobs continuously. |
| E10 | Security + Policy | Redaction, authorization, approval gates, safe storage. |
| E11 | Productization | Monetizable deliverable packages. |

## 2. E00 Governance + Repo Standards

### E00-T01 Create canonical docs

Sub-tasks:

- create `README.md`
- create `PROJECT.md`
- create `ROADMAP.md`
- create `ARCHITECTURE.md`
- create `OBSERVABILITY.md`
- create `SECURITY.md`
- create `AGENTS.md`
- create `WORKFLOWS.md`
- create `SKILLS.md`
- create docs index

Definition of Done:

- every doc has clear ownership
- docs link to each other
- no doc becomes a junk drawer

### E00-T02 Create machine-readable registries

Sub-tasks:

- `config/foundry/epics.yaml`
- `config/foundry/prompt-chains.yaml`
- `config/foundry/rules.yaml`
- `config/foundry/tasks.yaml`
- `config/foundry/agents.yaml`
- `config/foundry/workflows.yaml`

Definition of Done:

- YAML is valid
- every ID is stable
- every task has status, priority, dependencies, and acceptance criteria

## 3. E01 ForgeOS Host Runtime

### E01-T01 Full command center installer

Sub-tasks:

- recovery base installer
- ZSH productivity installer
- desktop command center installer
- observability center installer
- performance tuning installer
- security hardening installer
- dictation/accessibility installer
- TUI build installer
- full wrapper script

Acceptance Criteria:

- fresh Debian can clone and run `bash scripts/install-full-command-center.sh`
- logs are written
- state files are written
- reboot instructions are printed

### E01-T02 Forge TUI

Sub-tasks:

- main menu
- install screen
- desktop screen
- security/performance screen
- ops/doctor screen
- logs/observability screen
- status messages
- command execution wrapper

Acceptance Criteria:

- `forge-tui` builds
- each screen opens
- keybindings work
- shell fallback exists

## 4. E02 Observability Center

### E02-T01 SQLite schema

Sub-tasks:

- events table
- agent_runs table
- model_calls table
- tool_calls table
- compiler_runs table
- artifacts table
- wiki_pages table
- wiki_edges table
- summary views

Acceptance Criteria:

- schema applies with sqlite3
- views return results
- indexes exist for common queries

### E02-T02 Event CLI tools

Sub-tasks:

- `forge-event`
- `forge-model-call`
- `forge-tool-call`
- `forge-compile-log`
- `forge-observe`

Acceptance Criteria:

- commands write JSONL
- commands write SQLite rows
- `forge-observe` prints recent data

### E02-T03 Middleware wrappers

Sub-tasks:

- shell command wrapper
- MCP tool logger
- model gateway logger
- browser worker logger
- compiler logger

Acceptance Criteria:

- every tool call can emit `tool_calls`
- every model call can emit `model_calls`
- every compiler run can emit `compiler_runs`

## 5. E03 Capture Worker Runtime

### E03-T01 Capture job schema

Sub-tasks:

- define job ID
- define authorized URL
- define capture mode
- define schedule
- define headers policy
- define cookie policy
- define redaction policy
- define output paths

Acceptance Criteria:

- job validates
- policy is explicit
- unsafe jobs are rejected

### E03-T02 Playwright capture worker

Sub-tasks:

- launch browser
- isolate profile
- navigate URL
- record HAR
- capture screenshot
- save HTML
- write manifest
- emit events

Acceptance Criteria:

- one authorized page captured
- artifacts saved
- event logged

### E03-T03 mitmdump capture worker

Sub-tasks:

- create mitmproxy addon
- hook request
- hook response
- save flows
- redact sensitive headers
- write manifest
- emit events

Acceptance Criteria:

- flow file exists
- request/response metadata extracted
- redaction verified

### E03-T04 HAR importer

Sub-tasks:

- accept HAR path
- parse entries
- extract method/url/status/mime
- store raw artifact reference
- emit import event

Acceptance Criteria:

- sample HAR imports
- SQLite rows created

## 6. E04 SQLite Mirror

### E04-T01 Mirror schema

Sub-tasks:

- sites
- capture_sessions
- requests
- responses
- endpoints
- parameters
- schemas
- examples
- workflow_steps

Acceptance Criteria:

- schema applies cleanly
- foreign keys link artifacts

### E04-T02 Normalizer

Sub-tasks:

- group requests by host/path/method
- remove cache noise
- redact secrets
- infer path params
- infer query params
- infer JSON shape
- track versions

Acceptance Criteria:

- duplicate requests collapse
- endpoint examples remain linked

## 7. E05 Contract Compiler

### E05-T01 OpenAPI compiler

Sub-tasks:

- endpoint rows to paths
- method summaries
- parameter schemas
- request body schemas
- response schemas
- examples
- tags
- source links

Acceptance Criteria:

- generated OpenAPI validates
- every operation links to source capture

### E05-T02 Arazzo compiler

Sub-tasks:

- infer workflow sequence
- define inputs
- link OpenAPI operations
- define success criteria
- define failure steps

Acceptance Criteria:

- one workflow generated from captured sequence

### E05-T03 Zod/Pydantic compilers

Sub-tasks:

- generate model files
- generate validators
- generate examples
- generate tests

Acceptance Criteria:

- generated code imports
- sample payload validates

## 8. E06 Tool Generator

### E06-T01 Cobra CLI generator

Sub-tasks:

- generate command tree
- generate flags
- generate config loading
- generate request builder
- generate SQLite mirror query command
- generate docs

Acceptance Criteria:

- generated CLI builds
- command can query mirror

### E06-T02 REST wrapper generator

Sub-tasks:

- Hono routes
- validation middleware
- cache middleware
- response shape
- OpenAPI route docs

Acceptance Criteria:

- endpoint serves local mirror data

### E06-T03 MCP generator

Sub-tasks:

- FastMCP server
- tools over SQLite mirror
- resources for artifacts
- prompts for workflows

Acceptance Criteria:

- MCP server starts
- tool returns mirror result

## 9. E07 Agent Runtime

### E07-T01 Mirror-first PydanticAI agent

Sub-tasks:

- define agent role
- define tools
- enforce mirror-first rule
- log model/tool calls
- create eval

Acceptance Criteria:

- agent answers from SQLite
- live capture requires approval

### E07-T02 Policy engine

Sub-tasks:

- authorization policy
- stale mirror policy
- live capture approval
- secrets redaction gate
- dangerous command gate

Acceptance Criteria:

- unsafe capture job is rejected

## 10. E08 LLM Wiki

### E08-T01 Wiki schema and folder standard

Sub-tasks:

- page frontmatter
- page kinds
- page status
- graph edge types
- wiki indexer

Acceptance Criteria:

- page is indexed into SQLite
- edge is created

### E08-T02 Wiki compilers

Sub-tasks:

- project page generator
- endpoint page generator
- workflow page generator
- decision page generator
- monetization page generator

Acceptance Criteria:

- generated pages are traceable to source artifacts

## 11. E09 Jetson 24/7 Node

### E09-T01 Jetson profile

Sub-tasks:

- static LAN docs
- SSH setup
- Docker/Podman runtime
- systemd worker services
- storage directories
- health checks

Acceptance Criteria:

- Jetson can run capture-worker service
- workstation can query status

### E09-T02 Worker scheduler

Sub-tasks:

- scheduled captures
- job queue
- retry policy
- backoff
- health events

Acceptance Criteria:

- scheduled authorized job runs repeatedly

## 12. E10 Security + Policy

### E10-T01 Redaction

Sub-tasks:

- redact auth headers
- redact cookies
- redact tokens
- redact emails if policy requires
- redact payment/PII patterns
- write redaction report

Acceptance Criteria:

- raw sensitive fields are not promoted

### E10-T02 Capture authorization

Sub-tasks:

- allowed target registry
- owner/client field
- scope field
- proof/notes field
- expiration date

Acceptance Criteria:

- capture requires target policy

## 13. E11 Productization

### E11-T01 Deliverable generator

Sub-tasks:

- API map report
- endpoint spreadsheet export
- OpenAPI package
- MCP tool pack
- CLI package
- implementation README
- client handoff docs

Acceptance Criteria:

- one capture can produce a sellable package

## 14. Cross-Cutting TODOs

- Add tests for every compiler.
- Add fixtures for HAR, mitmproxy flow, OpenAPI, and SQLite mirror.
- Add CI validation for generated contracts.
- Add redaction tests.
- Add evals for mirror-first behavior.
- Add docs for Jetson deployment.
- Add dashboard after CLI/TUI works.
