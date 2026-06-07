# forge-pi-kit for ForgeOS

`forge-pi-kit` is the ForgeOS opinionated profile pack for running Pi as a contract-first, tool-routed, code-generation agent.

It provides the batteries-included layer for Pi agent workflows without colliding with the existing `oh-my-pi` project name.

It should provide:

- ready-to-use Pi profiles
- RunPod/vLLM connection templates
- ForgeOS contract wrapper defaults
- OpenAPI Generator profiles
- Cobra/Go CLI generation rules
- Arazzo workflow codegen rules
- tool gateway policies
- reusable prompts
- validation checklists
- starter task packs

## Relationship to pi-contract-wrapper

```txt
pi-contract-wrapper = enforcement layer
forge-pi-kit        = batteries-included profile pack
```

The wrapper defines how Pi must behave.

`forge-pi-kit` gives Pi the curated profiles, presets, aliases, workflows, and starter tasks needed to work productively inside ForgeOS.

## Directory layout

```txt
forgeos/wrappers/forge-pi-kit/
  README.md
  profiles/default.yaml
  profiles/runpod-vllm.yaml
  presets/contract-first.yaml
  presets/sdk-factory.yaml
  presets/cobra-cli-factory.yaml
  presets/arazzo-workflow-factory.yaml
  prompts/forge-pi-kit.md
  tasks/bootstrap.md
```

## Core philosophy

Pi should not guess project structure.

Pi should:

1. Read the contracts.
2. Compile a context pack.
3. Ask for gateway tools.
4. Generate from OpenAPI, SQLite, Cobra, and Arazzo contracts.
5. Validate results.
6. Update progress.

## Default stack

```txt
Agent: Pi
Model backend: RunPod vLLM
API shape: OpenAI-compatible
Contract layer: ForgeOS contracts
Tool execution: Forge Tool Gateway
API contract: OpenAPI 3.1
Workflow contract: Arazzo
Database contract: SQLite schema.sql
CLI contract: Cobra/Go
Codegen: OpenAPI Generator
```

## First local use

From the repository root:

```txt
Read these files first:

forgeos/wrappers/pi-contract-wrapper/README.md
forgeos/wrappers/pi-contract-wrapper/wrapper.contract.yaml
forgeos/wrappers/forge-pi-kit/profiles/runpod-vllm.yaml
forgeos/wrappers/forge-pi-kit/prompts/forge-pi-kit.md
```

Then configure the RunPod environment template under:

```txt
forgeos/integrations/pi-runpod-vllm/.env.example
```
