# forge-pi-kit Quickstart

This is the copy/paste path for configuring Pi to run inside ForgeOS as a contract-first coding agent.

## 0. Pull the latest repo

```bash
git pull
```

## 1. Read the active wrapper files

```bash
cat forgeos/wrappers/forge-pi-kit/README.md
cat forgeos/wrappers/forge-pi-kit/profiles/runpod-vllm.yaml
cat forgeos/wrappers/pi-contract-wrapper/wrapper.contract.yaml
cat forgeos/wrappers/pi-contract-wrapper/prompts/pi-contract-system.md
```

## 2. Create local ForgeOS runtime folders

```bash
mkdir -p .forgeos/profiles/pi-runpod-vllm
mkdir -p .forgeos/context
mkdir -p .forgeos/logs
```

## 3. Create local RunPod environment file

```bash
cp forgeos/integrations/pi-runpod-vllm/.env.example .env.forgeos
nano .env.forgeos
```

Fill in at least:

```bash
RUNPOD_API_KEY=your_runpod_api_key
RUNPOD_ENDPOINT_ID=your_runpod_endpoint_id
RUNPOD_MODEL=your_vllm_model_name
FORGEOS_PROJECT_ROOT=$PWD
FORGEOS_TOOL_GATEWAY_URL=http://127.0.0.1:8787
```

The RunPod OpenAI-compatible base URL should be:

```bash
https://api.runpod.ai/v2/YOUR_ENDPOINT_ID/openai/v1
```

## 4. Copy the Pi profile templates into the local runtime folder

```bash
cp forgeos/integrations/pi-runpod-vllm/config/pi.runpod.example.json .forgeos/profiles/pi-runpod-vllm/pi.runpod.json
cp forgeos/integrations/pi-runpod-vllm/prompts/forgeos-system-prompt.md .forgeos/profiles/pi-runpod-vllm/forgeos-system-prompt.md
cp forgeos/wrappers/pi-contract-wrapper/prompts/pi-contract-system.md .forgeos/profiles/pi-runpod-vllm/pi-contract-system.md
cp forgeos/wrappers/forge-pi-kit/prompts/forge-pi-kit.md .forgeos/profiles/pi-runpod-vllm/forge-pi-kit.md
```

## 5. Confirm required contract files exist

```bash
ls contracts/schema.sql
ls contracts/openapi.yaml
ls contracts/arazzo.yaml
ls contracts/cobra.yaml
```

If one is missing, create a starter placeholder before asking Pi to implement code.

```bash
mkdir -p contracts
[ -f contracts/schema.sql ] || printf '%s\n' '-- ForgeOS SQLite schema contract' > contracts/schema.sql
[ -f contracts/openapi.yaml ] || printf '%s\n' 'openapi: 3.1.0' 'info:' '  title: ForgeOS' '  version: 0.1.0' 'paths: {}' > contracts/openapi.yaml
[ -f contracts/arazzo.yaml ] || printf '%s\n' 'arazzo: 1.0.1' 'info:' '  title: ForgeOS Workflows' '  version: 0.1.0' 'sourceDescriptions: []' 'workflows: []' > contracts/arazzo.yaml
[ -f contracts/cobra.yaml ] || printf '%s\n' 'version: 0.1.0' 'name: forge' 'commands: []' > contracts/cobra.yaml
```

## 6. Confirm Forge Tool Gateway contracts exist

```bash
ls forgeos/tool-gateway/tools.json
ls forgeos/tool-gateway/permissions.yaml
ls forgeos/tool-gateway/openapi.yaml
```

## 7. Build the first context pack manually

Until the `forge pi compile-context` command exists, create the first context pack with this manual command:

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

## 8. First task to give Pi

Paste this into Pi:

```txt
You are running inside ForgeOS using forge-pi-kit and pi-contract-wrapper.

Load this local context file first:

.forgeos/context/pi-contract-context.md

Task:
Read the ForgeOS contracts, summarize the authority order, validate what files are present, and create a small task graph. Do not implement application code yet. Do not invent routes, tables, commands, flags, workflow steps, or SDK methods that are not represented in the contracts.
```

## 9. Expected first output

Pi should produce:

```txt
contract summary
missing contract warnings, if any
task graph proposal
validation checklist
next smallest task
```

## 10. Next commands after the Go CLI exists

These commands are the intended final interface:

```bash
forge contracts validate
forge pi compile-context --profile forge-pi-kit-runpod-vllm
forge pi run --task "validate contracts and build task graph"
forge generate sdk --language go
forge generate sdk --language typescript
forge generate workflow --workflow <workflow-id>
```

Until those commands are implemented, use this QUICKSTART as the manual workflow.
