# Machine-Readable Registry

## 1. Purpose

Markdown is for humans.

YAML/JSON registries are for agents, CLIs, CI, dashboards, compilers, and schedulers.

Forge Foundry should use both.

## 2. Required Registries

```text
config/foundry/
  project.yaml
  epics.yaml
  tasks.yaml
  agents.yaml
  workflows.yaml
  prompt-chains.yaml
  rules.yaml
  targets.yaml
  capture-jobs.yaml
  compilers.yaml
  tools.yaml
  products.yaml
```

## 3. Registry Rules

1. Every object needs a stable ID.
2. Every object needs a status.
3. Every task needs acceptance criteria.
4. Every generated artifact needs a source reference.
5. Every workflow needs inputs, outputs, and gates.
6. Every capture target needs authorization metadata.
7. Every policy must be machine-enforceable where possible.

## 4. ID Conventions

```text
EPIC-001
TASK-E03-001
SLICE-0001
CHAIN-RESEARCH-001
RULE-MIRROR-001
AGENT-SCOUT
TARGET-example-com
CAPTURE-2026-0001
COMPILER-OPENAPI-001
TOOL-MIRROR-QUERY
```

## 5. Status Values

```text
proposed
planned
ready
in_progress
blocked
needs_review
validated
complete
deprecated
rejected
```

## 6. Priority Values

```text
P0  critical path
P1  important next
P2  useful expansion
P3  later polish
```

## 7. Example Task Object

```yaml
id: TASK-E03-002
title: Build Playwright capture worker
status: planned
priority: P1
epic: E03
phase: capture-worker-runtime
owner_agent: operator
dependencies:
  - TASK-E03-001
inputs:
  - capture job YAML
outputs:
  - HAR artifact
  - screenshot artifact
  - capture manifest
acceptance_criteria:
  - one authorized page can be captured
  - artifacts are saved
  - observability event is emitted
  - redaction policy is applied
```

## 8. Example Prompt Chain Object

```yaml
id: CHAIN-CAPTURE-PLAN-001
name: Capture Planning
owner_agent: scout
status: planned
inputs:
  - target_url
  - authorization_scope
outputs:
  - capture plan markdown
  - capture job YAML
rules:
  - RULE-AUTH-001
  - RULE-REDACT-001
```

## 9. Example Rule Object

```yaml
id: RULE-MIRROR-001
name: Mirror first
severity: required
statement: Agents must query SQLite mirrors before raw web or raw artifacts.
verification:
  - inspect tool call log
  - check raw artifact reads
  - check model context payload size
```

## 10. Recommended Validation

Add scripts:

```text
scripts/validate-foundry-config.sh
scripts/validate-capture-job.sh
scripts/validate-prompt-chains.sh
scripts/validate-rules.sh
```

Later add JSON Schema:

```text
contracts/schemas/foundry-task.schema.json
contracts/schemas/foundry-rule.schema.json
contracts/schemas/foundry-prompt-chain.schema.json
contracts/schemas/foundry-capture-job.schema.json
```
