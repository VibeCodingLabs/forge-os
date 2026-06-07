# oh-my-pi for ForgeOS

`oh-my-pi` is the ForgeOS opinionated profile pack for running Pi as a contract-first, tool-routed, code-generation agent.

Think of it like `oh-my-zsh`, but for Pi agent workflows.

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
oh-my-pi           = batteries-included profile pack
```

The wrapper defines how Pi must behave.

`oh-my-pi` gives Pi the curated profiles, presets, aliases, workflows, and starter tasks needed to work productively inside ForgeOS.

## Directory layout

```txt
forgeos/wrappers/oh-my-pi/
  README.md
  profiles/default.yaml
  profiles/runpod-vllm.yaml
  presets/contract-first.yaml
  presets/sdk-factory.yaml
  presets/cobra-cli-factory.yaml
  presets/arazzo-workflow-factory.yaml
  prompts/oh-my-pi.md
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
forgeos/wrappers/oh-my-pi/profiles/runpod-vllm.yaml
forgeos/wrappers/oh-my-pi/prompts/oh-my-pi.md
```

Then configure the RunPod environment template under:

```txt
forgeos/integrations/pi-runpod-vllm/.env.example
```
