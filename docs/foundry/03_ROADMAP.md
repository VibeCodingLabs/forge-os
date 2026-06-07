# Forge Foundry Roadmap

## 1. Roadmap Strategy

Use a hybrid roadmap:

1. Build one tiny end-to-end vertical spine first.
2. Expand the foundation in layers.
3. Ship each tool/plugin/compiler as its own usable MVP slice.
4. Keep every phase observable, testable, and rollback-safe.

The first success is not a huge platform.

The first success is:

```text
One authorized URL
  -> one capture
  -> one SQLite mirror row
  -> one OpenAPI draft
  -> one generated tool
  -> one agent query using local mirror
  -> one observability trace
  -> one wiki page
```

## 2. Waves, Phases, Milestones, Slices

### Definitions

| Term | Meaning |
|---|---|
| Wave | Large strategic push across multiple phases. |
| Phase | Major capability layer. |
| Milestone | Verifiable outcome inside a phase. |
| Slice | Tiny end-to-end usable implementation. |
| Task | Concrete unit of work. |
| Sub-task | Smallest trackable implementation step. |

## 3. Wave 0: Foundation Spine

### Goal

Prove the capture-to-contract loop works once.

### Phase 0.1: Repo + State Spine

Milestones:

- create repo skeleton
- create observability schema
- create SQLite DB
- create JSONL logs
- create raw/generated/wiki folders
- create first run manifest

Slice:

```text
forge-event writes JSONL + SQLite event
```

Acceptance Criteria:

- `forge-event test.event "hello"` writes to logs and DB
- `forge-observe` displays the event

### Phase 0.2: Capture Spine

Milestones:

- create capture job schema
- run one authorized capture
- save HAR or mitmproxy flow
- create capture manifest

Slice:

```text
capture URL -> raw/har/example.har -> SQLite capture row
```

Acceptance Criteria:

- capture artifact exists
- capture manifest exists
- SQLite row references artifact path

### Phase 0.3: Contract Spine

Milestones:

- parse HAR/flow
- extract host/path/method/status
- infer endpoint rows
- generate OpenAPI draft

Slice:

```text
HAR -> endpoint rows -> openapi.yaml
```

Acceptance Criteria:

- at least one endpoint is generated
- OpenAPI validates
- source artifact links exist

### Phase 0.4: Tool Spine

Milestones:

- generate Cobra command stub
- generate FastMCP tool stub
- generate REST route stub
- generate Pydantic/Zod models

Slice:

```text
endpoint row -> CLI + MCP + schema
```

Acceptance Criteria:

- generated CLI lists endpoint
- MCP tool can query mirror
- Pydantic model imports
- Zod schema imports

### Phase 0.5: Agent Spine

Milestones:

- define mirror-first agent rule
- create one PydanticAI agent tool
- query SQLite mirror
- generate answer without reading raw HAR

Slice:

```text
agent question -> SQLite mirror query -> answer
```

Acceptance Criteria:

- agent uses mirror tool
- raw artifact is not read unless explicitly requested
- model/tool call logged

## 4. Wave 1: Local ForgeOS Command Center

### Goal

Make ForgeOS a reliable operator workstation.

Phases:

1. Full command center installer
2. River/Waybar/Eww desktop
3. performance tuning
4. hardening/firewall/AV
5. dictation/accessibility
6. forge-tui command center
7. observability center

Acceptance Criteria:

- fresh Debian can clone repo and run installer
- `forge-tui` launches
- `forge-doctor` produces report
- River starts
- logs and DB exist
- firewall is active

## 5. Wave 2: Capture Worker Runtime

### Goal

Run 24/7 authorized capture jobs locally or on Jetson.

Phases:

1. capture job schema
2. queue system
3. Playwright worker
4. mitmdump worker
5. HAR importer
6. artifact store
7. redaction gate
8. capture scheduler

Milestones:

- capture one site manually
- capture one workflow replay
- import one HAR
- process one mitmproxy flow
- run scheduled capture
- generate capture report

## 6. Wave 3: SQLite Mirror System

### Goal

Normalize captures into structured queryable mirrors.

Phases:

1. mirror schema
2. endpoint extractor
3. request/response store
4. schema inference
5. dedupe/versioning
6. mirror query API
7. mirror CLI
8. mirror MCP tools

Acceptance Criteria:

- endpoints table populated
- examples linked
- versioning works
- mirror query returns useful summaries
- agents can answer from mirror

## 7. Wave 4: Contract Compiler

### Goal

Generate contracts and wrappers from mirrors.

Phases:

1. OpenAPI compiler
2. Arazzo workflow compiler
3. Zod compiler
4. Pydantic compiler
5. Cobra CLI compiler
6. REST wrapper compiler
7. FastMCP compiler
8. SDK compiler
9. docs compiler

Acceptance Criteria:

- generated OpenAPI validates
- generated models import
- generated CLI builds
- generated MCP server starts
- generated docs link to source rows

## 8. Wave 5: Agent Runtime + Mirror-First Rules

### Goal

Agents perform useful work while minimizing token usage.

Phases:

1. PydanticAI runtime
2. mirror query tools
3. policy engine
4. approval gates
5. model call logger
6. tool call logger
7. replayable run logs
8. eval harness

Acceptance Criteria:

- every model call is logged
- every tool call is logged
- agent refuses live capture without permission
- agent uses local mirror first
- run can be replayed from artifacts

## 9. Wave 6: LLM Wiki

### Goal

Create a durable project intelligence wiki.

Phases:

1. wiki folder standard
2. wiki page schema
3. wiki SQLite index
4. wiki edge builder
5. raw-to-wiki compiler
6. project pages
7. endpoint pages
8. workflow pages
9. decision pages
10. monetization pages

Acceptance Criteria:

- wiki page generated from capture
- wiki page indexed in SQLite
- wiki edge connects project -> endpoint -> tool
- wiki can answer project status after context reset

## 10. Wave 7: Productization + Monetization

### Goal

Package outputs as sellable services/products.

Phases:

1. service packages
2. templates
3. pricing matrix
4. demo scripts
5. client onboarding docs
6. deliverable generator
7. proposal generator
8. case study generator

Products:

- API Map Package
- Internal MCP Tool Pack
- OpenAPI Rescue Package
- Workflow Automation Package
- Agent Observability Package
- Local Mirror Token Saver

## 11. Release Gates

### Alpha

- local installer works
- observability DB works
- one capture pipeline works
- one mirror query works
- one generated OpenAPI works

### Beta

- Jetson worker runs scheduled captures
- MCP tools generated
- CLI generated
- wiki generated
- agent uses mirror-first rules

### v1

- reusable capture-to-contract pipeline
- strong redaction
- docs and runbooks
- monetization templates
- stable dashboard/TUI
- repeatable client deliverable

## 12. Global Definition of Done

A slice is not done unless:

- code exists
- docs exist
- logs exist
- schema exists if data crosses boundaries
- test or validation exists
- observability event is emitted
- failure mode is documented
- rollback path is documented
