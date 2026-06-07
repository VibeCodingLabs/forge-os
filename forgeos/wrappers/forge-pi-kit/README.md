# forge-pi-kit for ForgeOS

`forge-pi-kit` is the ForgeOS opinionated profile pack for running Pi as a contract-first, tool-routed, code-generation agent.

It provides the batteries-included layer for Pi agent workflows without colliding with the existing `oh-my-pi` project name.

## Start here

For copy/paste setup commands, read:

```bash
cat forgeos/wrappers/forge-pi-kit/QUICKSTART.md
```

## What it provides

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
  QUICKSTART.md
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

## Quick local setup

From the repository root:

```bash
git pull
mkdir -p .forgeos/profiles/pi-runpod-vllm .forgeos/context .forgeos/logs
cp forgeos/integrations/pi-runpod-vllm/.env.example .env.forgeos
cp forgeos/integrations/pi-runpod-vllm/config/pi.runpod.example.json .forgeos/profiles/pi-runpod-vllm/pi.runpod.json
cp forgeos/wrappers/pi-contract-wrapper/prompts/pi-contract-system.md .forgeos/profiles/pi-runpod-vllm/pi-contract-system.md
cp forgeos/wrappers/forge-pi-kit/prompts/forge-pi-kit.md .forgeos/profiles/pi-runpod-vllm/forge-pi-kit.md
```

Then edit:

```bash
nano .env.forgeos
```

Required values:

```bash
RUNPOD_API_KEY=your_runpod_api_key
RUNPOD_ENDPOINT_ID=your_runpod_endpoint_id
RUNPOD_MODEL=your_vllm_model_name
FORGEOS_PROJECT_ROOT=$PWD
FORGEOS_TOOL_GATEWAY_URL=http://127.0.0.1:8787
```

## First manual context pack

Until the Go CLI command exists, create the first context pack manually:

```bash
cat \
  forgeos/wrappers/pi-contract-wrapper/prompts/pi-contract-system.md \
  forgeos/wrappers/forge-pi-kit/prompts/forge-pi-kit.md \
  contracts/schema.sql \
  contracts/openapi.yaml \
  contracts/arazzo.yaml \
  contracts/cobra.yaml \
  forgeos/tool-gateway/tools.json \
  forgeos/tool-gateway/permissions.yaml \
  > .forgeos/context/pi-contract-context.md
```

Then paste the first task from:

```bash
cat forgeos/wrappers/forge-pi-kit/QUICKSTART.md
```

## Intended final CLI

These commands are the target interface once the ForgeOS Go CLI is implemented:

```bash
forge contracts validate
forge pi compile-context --profile forge-pi-kit-runpod-vllm
forge pi run --task "validate contracts and build task graph"
forge generate sdk --language go
forge generate sdk --language typescript
forge generate workflow --workflow <workflow-id>
```
