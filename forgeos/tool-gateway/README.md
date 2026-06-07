# ForgeOS Tool Gateway

The Forge Tool Gateway is the control plane between an AI coding agent and ForgeOS project tools.

The gateway exists so the model can request actions without directly owning execution. Contracts, permissions, and validation stay in the repository.

## Responsibilities

```txt
agent tool request
  -> check tools.json
  -> check permissions.yaml
  -> validate input schema
  -> run the mapped command/service
  -> validate output shape
  -> write telemetry/progress log
  -> return result to agent
```

## Core files

```txt
forgeos/tool-gateway/tools.json
forgeos/tool-gateway/permissions.yaml
forgeos/tool-gateway/openapi.yaml
```

## MVP tools

- `forge.contracts.validate`
- `forge.openapi.validate`
- `forge.sqlite.validate`
- `forge.taskgraph.build`
- `forge.progress.update`

## Execution policy

The gateway should start conservative:

- no arbitrary shell by default
- no network scraping by default
- no secret printing
- no destructive filesystem actions
- project-root scoped file access
- explicit allowlist for every tool

## First implementation target

Build this as a small local HTTP service first:

```txt
POST /tools/forge.contracts.validate
POST /tools/forge.openapi.validate
POST /tools/forge.sqlite.validate
POST /tools/forge.taskgraph.build
POST /tools/forge.progress.update
```

Later it can be wrapped as:

- MCP server
- Cobra CLI
- Tauri sidecar
- queue worker
- OpenAPI-generated SDK
