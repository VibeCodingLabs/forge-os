# ForgeOS Pi Contract Context Pack

This file describes the context pack that the wrapper should compile before handing work to Pi.

## Context pack order

1. Wrapper system prompt
2. User task
3. Contract authority order
4. SQLite schema contract
5. OpenAPI contract
6. Arazzo workflow contract
7. Cobra CLI contract
8. Architecture spec
9. Acceptance criteria
10. Definition of done
11. Tool registry
12. Tool permissions
13. Current progress

## Compiled output target

```txt
.forgeos/context/pi-contract-context.md
```

## Context pack template

```md
# ForgeOS Pi Contract Context

## User Task
{{task}}

## Contract Authority
{{authority_order}}

## SQLite Schema
{{schema_sql}}

## OpenAPI 3.1 Contract
{{openapi_yaml}}

## Arazzo Workflows
{{arazzo_yaml}}

## Cobra CLI Contract
{{cobra_yaml}}

## Architecture
{{architecture_md}}

## Acceptance Criteria
{{acceptance_criteria_md}}

## Definition of Done
{{definition_of_done_md}}

## Tool Registry
{{tools_json}}

## Tool Permissions
{{permissions_yaml}}

## Current Progress
{{progress_md}}
```

## Wrapper requirement

The context pack should be regenerated for every agent task so Pi always sees the latest contracts and progress state.
