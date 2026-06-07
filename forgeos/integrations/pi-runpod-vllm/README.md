# ForgeOS Pi + RunPod vLLM Integration

This package prepares ForgeOS to use an OpenAI-compatible RunPod vLLM endpoint as the model backend for coding agents such as `earendilworks/pi`, while forcing the agent to operate through ForgeOS contracts and a validated tool gateway.

## Target architecture

```txt
pi coding agent
  -> OpenAI-compatible RunPod vLLM endpoint
  -> model response / tool call request
  -> Forge Tool Gateway
  -> contract validation
  -> allowlisted tool execution
  -> progress + telemetry logs
```

The model is not trusted as the source of authority. The repository contracts are the authority.

## Files added

```txt
forgeos/integrations/pi-runpod-vllm/
  README.md
  .env.example
  config/pi.runpod.example.json
  prompts/forgeos-system-prompt.md
  scripts/setup-pi-runpod-vllm.sh
  scripts/validate-integration.sh
```

Related gateway files:

```txt
forgeos/tool-gateway/
  README.md
  tools.json
  permissions.yaml
  openapi.yaml
```

River prep:

```txt
forgeos/desktop/river/
  README.md
  install-river-dev-env.sh
  config/init
```

## Required environment

Copy the example env file:

```bash
cp forgeos/integrations/pi-runpod-vllm/.env.example .env.forgeos
nano .env.forgeos
```

Set:

```bash
RUNPOD_API_KEY=your_runpod_key
RUNPOD_ENDPOINT_ID=your_endpoint_id
FORGEOS_PROJECT_ROOT=$PWD
FORGEOS_TOOL_GATEWAY_URL=http://127.0.0.1:8787
```

The OpenAI-compatible base URL should resolve to:

```txt
https://api.runpod.ai/v2/${RUNPOD_ENDPOINT_ID}/openai/v1
```

## Bootstrap

Run:

```bash
bash forgeos/integrations/pi-runpod-vllm/scripts/setup-pi-runpod-vllm.sh
```

Then validate:

```bash
bash forgeos/integrations/pi-runpod-vllm/scripts/validate-integration.sh
```

## Contract enforcement rules

The coding agent must always load:

```txt
specs/PROJECT_OVERVIEW.md
specs/ARCHITECTURE.md
contracts/openapi.yaml
contracts/schema.sql
tasks/acceptance-criteria.md
tasks/definition-of-done.md
forgeos/tool-gateway/tools.json
forgeos/tool-gateway/permissions.yaml
```

The agent may propose tool calls, but only the Forge Tool Gateway may execute tools.

## Recommended first vertical slice

1. Configure RunPod vLLM endpoint.
2. Configure Pi to use the RunPod OpenAI-compatible base URL.
3. Start the Forge Tool Gateway.
4. Ask Pi to read the ForgeOS system prompt.
5. Ask Pi to validate repo contracts.
6. Confirm rejected calls are denied when they are not allowlisted.
7. Confirm progress logs are written after each task.
