# Forge Foundry Rules, Gotchas, and Pitfalls

## 1. Hard Rules

### RULE-001: Authorization Required

Only capture, crawl, replay, inspect, or automate targets that are owned, administered, contracted, or explicitly authorized.

### RULE-002: Mirror First

Agents must use local mirrors before raw web, raw docs, or live capture.

Order:

1. SQLite mirror
2. Generated contract
3. Generated CLI/MCP/REST tool
4. LLM wiki
5. Raw artifact
6. Live capture with approval

### RULE-003: Raw Captures Are Sensitive

HAR files, mitmproxy flows, headers, request bodies, response bodies, screenshots, cookies, and tokens must be treated as sensitive.

### RULE-004: Redact Before Promotion

No raw capture should be promoted to generated docs, wiki, code, or public artifacts before redaction.

### RULE-005: Generated Contracts Are Drafts Until Validated

OpenAPI, Arazzo, Zod, Pydantic, SDKs, CLIs, and MCP tools generated from traffic are inferred until tested and reviewed.

### RULE-006: Observability Is Mandatory

Every meaningful agent run, tool call, model call, compiler run, artifact creation, policy decision, and approval event should be logged.

### RULE-007: SQLite Is Source of Truth for v1

Redis and Qdrant are secondary systems.

SQLite + artifacts + JSONL + Git are the v1 source of truth.

### RULE-008: No Agent Owns Canonical Truth

Agents can propose, draft, summarize, and generate. Canonical truth lives in reviewed repo files, schemas, database rows, artifacts, and Git commits.

### RULE-009: Do Not Inline Huge Artifacts Into Prompts

Store bodies as artifacts. Send compact summaries and references to agents.

### RULE-010: Tool Calls Need Contracts

Every generated tool must have input schema, output schema, error model, examples, and logging.

## 2. Capture Gotchas

### GOTCHA-001: HAR Files Leak Secrets

HAR files can contain:

- cookies
- bearer tokens
- session IDs
- emails
- internal IDs
- request bodies
- response bodies
- auth headers

Mitigation:

- redact by default
- store raw privately
- only promote sanitized summaries

### GOTCHA-002: Browser Noise Looks Like API Surface

Modern apps emit many noisy calls:

- analytics
- telemetry
- ads
- fonts
- static assets
- hot reload
- error tracking
- feature flags

Mitigation:

- filter static assets
- group by domain/path/method
- confidence-score endpoints

### GOTCHA-003: Captured APIs May Not Be Stable

XHR endpoints are sometimes private implementation details.

Mitigation:

- mark inferred/private endpoints
- avoid claiming official API status
- prefer official docs when available

### GOTCHA-004: Authenticated Flows Are Risky

Authenticated captures may include private data.

Mitigation:

- use test accounts
- use dummy data
- redact aggressively
- separate private raw storage

### GOTCHA-005: Replay Can Mutate State

Generated replay commands can create, update, or delete data.

Mitigation:

- default replay disabled
- require approval for mutating methods
- tag GET/POST/PUT/PATCH/DELETE separately
- dry-run where possible

## 3. Architecture Pitfalls

### PITFALL-001: Starting With Qdrant Instead of SQLite

Vector search is useful later, but it is not the foundation.

Start with SQLite rows and deterministic queries.

### PITFALL-002: Making Redis the Memory Layer

Redis is not the durable truth layer.

Use Redis for queues/cache. Use SQLite/JSONL/artifacts/Git for durable state.

### PITFALL-003: Letting Agents Read Everything

Agents should not read raw captures, raw docs, giant repo trees, and browser dumps unless needed.

They should query compact mirrors.

### PITFALL-004: Building UI Before Runtime

A dashboard without capture, mirror, compiler, and observability pipelines is a shell.

Build CLI/TUI/runtime first.

### PITFALL-005: Compiler Without Validation

Generated OpenAPI/Zod/Pydantic/CLI/MCP code must be validated.

### PITFALL-006: No Artifact Traceability

Every generated output must link back to source artifacts and mirror rows.

### PITFALL-007: Treating Inference As Fact

Schema inference is not proof.

Use confidence scores and review states.

### PITFALL-008: Running 24/7 Workers Without Quotas

Jetson workers need quotas:

- disk cap
- request cap
- target allowlist
- retry limits
- log rotation
- CPU/memory caps

### PITFALL-009: Logs Become a Data Leak

Observability can leak secrets if raw prompts/responses/request bodies are logged.

Default to lifecycle metadata, not raw full bodies.

### PITFALL-010: One Giant Installer

One massive installer is hard to debug.

Use separate modules:

- base
- desktop
- observability
- security
- performance
- capture
- compiler
- agent runtime

## 4. Security Rules

### SEC-001: Target Allowlist

Capture workers must check an allowed target registry.

### SEC-002: Redaction Registry

Maintain patterns for:

- Authorization headers
- Cookie headers
- Set-Cookie headers
- API keys
- tokens
- emails
- phone numbers
- addresses
- payment-like fields

### SEC-003: Mutating Request Gate

POST, PUT, PATCH, DELETE replay requires approval.

### SEC-004: Sandbox Capture Workers

Browser and capture workers should run with isolated profiles and limited filesystem access.

### SEC-005: Secrets Never Reach Browser UI

API keys and provider keys must stay server-side.

### SEC-006: Raw Artifact Access Needs Roles

Raw captures are not public docs.

### SEC-007: Audit Every Approval

Approvals must be logged with timestamp, reason, scope, and operator.

## 5. Observability Rules

### OBS-001: Log Lifecycle by Default

Default logs should include:

- run started
- run completed
- run failed
- model/provider
- token totals
- latency
- status
- artifact references

Do not log raw token streams by default.

### OBS-002: Content-Address Large Bodies

Large request/response/prompt/output bodies go to artifact storage and are referenced by hash/path.

### OBS-003: Every Compiler Run Gets a Row

Contract/tool/wiki generators must write `compiler_runs` rows.

### OBS-004: Every Generated Artifact Gets a Row

Generated files must be registered as artifacts.

### OBS-005: Every Agent Run Gets a Run ID

Run IDs are required for replayability.

## 6. Token-Saving Rules

### TOK-001: Query Mirror First

Agents must search SQLite before asking the model to infer from raw data.

### TOK-002: Use Summaries, Not Dumps

Pass summaries and IDs, not full captures.

### TOK-003: Cache Model Results

Cache stable summaries and generated docs.

### TOK-004: Store Tool Outputs

Do not rerun expensive discovery if the mirror is fresh.

### TOK-005: Teach Agents the Schema

Agents should know the SQLite tables and query patterns.

## 7. Codegen Rules

### CODEGEN-001: Generated Code Lives Under `generated/`

Do not overwrite hand-written code without review.

### CODEGEN-002: Include Headers

Generated files should include:

- generator name
- source contract
- generated time
- warning that file is generated

### CODEGEN-003: Tests Required

Generated schemas/tools should include sample tests.

### CODEGEN-004: No Secrets in Fixtures

Fixtures must be sanitized.

### CODEGEN-005: Stable IDs

Operation IDs, tool IDs, schema IDs, and page IDs must be stable.

## 8. LLM Wiki Rules

### WIKI-001: Frontmatter Required

Every wiki page should have YAML frontmatter.

### WIKI-002: Draft Before Canonical

Generated pages start as draft.

### WIKI-003: Source Links Required

Every generated claim should link to source artifacts or mirror rows where possible.

### WIKI-004: Edges Matter

The wiki is also a graph.

Create edges:

- project uses tool
- endpoint belongs to site
- workflow calls endpoint
- agent generated artifact
- compiler produced file

### WIKI-005: No Fake Certainty

Use `unknown`, `inferred`, `needs_review`, and `confidence` when needed.

## 9. Jetson Rules

### JETSON-001: 24/7 Does Not Mean Unlimited

Set disk, CPU, memory, network, and schedule caps.

### JETSON-002: Workers Must Be Restartable

Every job should be replayable after reboot.

### JETSON-003: Logs Rotate

No worker should fill disk.

### JETSON-004: Capture Jobs Are Queued

No uncontrolled infinite capture loops.

### JETSON-005: Health Events Required

Heartbeat, failure, restart, and disk-pressure events must be logged.

## 10. Productization Gotchas

- Clients want outcomes, not architecture diagrams.
- Sell deliverables: API maps, CLIs, MCP tools, dashboards, docs, automation savings.
- Never promise official API coverage when endpoints are inferred.
- Show before/after token and time savings.
- Package with setup docs and security notes.
