# Forge Foundry Backlog and TODOs

## P0 — Must Exist Before Real Development

### P0-001 Validate existing ForgeOS installer

- Run full install on fresh Debian test machine.
- Save install logs.
- Fix package failures.
- Verify `forge-tui` builds.
- Verify `forge-doctor` runs.
- Verify River starts.
- Verify observability DB exists.

### P0-002 Add observability center smoke tests

- `forge-event smoke.test hello`
- `forge-model-call test-provider test-model test-route 1 2 3`
- `forge-tool-call test-tool ok 0`
- `forge-compile-log test-compiler input output`
- `forge-observe`

### P0-003 Create mirror schema

- sites
- capture_sessions
- requests
- responses
- endpoints
- parameters
- schemas
- examples
- capture_jobs
- target_allowlist

### P0-004 Create target authorization registry

- target ID
- URL/domain
- owner/client
- authorization basis
- scope
- expiration
- allowed methods
- allowed paths
- disallowed paths
- notes

### P0-005 Create redaction rules

- auth headers
- cookies
- bearer tokens
- API keys
- emails
- phone numbers
- payment-like patterns
- private IDs

### P0-006 Create first capture job format

- YAML example
- JSON Schema
- validation command
- safe defaults

### P0-007 Create HAR importer MVP

- parse HAR
- extract entries
- write SQLite rows
- link artifact
- emit event

### P0-008 Create OpenAPI compiler MVP

- read endpoint rows
- generate minimal OpenAPI
- validate output
- emit compiler event

## P1 — First Real Vertical Slice

### P1-001 Capture one authorized target

- create target allowlist entry
- run capture job
- save HAR
- import HAR
- generate endpoint catalog
- generate OpenAPI draft

### P1-002 Generate local mirror query CLI

- list sites
- list captures
- list endpoints
- show endpoint examples
- output JSON

### P1-003 Generate FastMCP mirror server

- query endpoint catalog
- query examples
- query wiki pages
- return compact summaries

### P1-004 Create PydanticAI mirror-first agent

- tool: query endpoints
- tool: query examples
- tool: query wiki
- rule: no live capture unless approved
- log model/tool calls

### P1-005 Create first wiki compiler

- generate site page
- generate endpoint summary page
- index in SQLite
- create wiki edges

### P1-006 Create eval for mirror-first compliance

- test prompt
- expected tool use
- fail if raw artifact read first

## P2 — Jetson Worker Node

### P2-001 Jetson install profile

- system packages
- Docker/Podman option
- static LAN docs
- storage directories
- systemd worker services

### P2-002 Capture worker daemon

- queue polling
- job execution
- artifact save
- event logging
- health heartbeat

### P2-003 Scheduler

- recurring jobs
- retry/backoff
- max captures per target
- disk caps
- time windows

### P2-004 Remote status command

- `forge node status jetson`
- list current jobs
- list recent events
- list disk usage

## P3 — Productization

### P3-001 Deliverable generator

- API map report
- OpenAPI package
- CLI package
- MCP package
- setup docs
- risk notes

### P3-002 Monetization templates

- offer one-pager
- pricing options
- proposal template
- demo script
- case study template

### P3-003 Dashboard

- capture timeline
- endpoint browser
- model cost view
- tool call view
- wiki browser
- generated artifact browser

## Continuous TODOs

- Keep docs updated.
- Keep schemas validated.
- Keep generated artifacts separate from canonical source.
- Add tests for every compiler.
- Add fixtures for every input type.
- Avoid unreviewed live captures.
- Keep raw artifacts private by default.
- Make everything replayable.
- Keep every step observable.
