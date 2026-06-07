# oh-my-pi Bootstrap Tasks

Use this checklist to bring Pi online as a ForgeOS contract-first coding agent.

## Phase 1: Profile files

- [ ] Read `forgeos/wrappers/oh-my-pi/README.md`.
- [ ] Read `forgeos/wrappers/oh-my-pi/profiles/default.yaml`.
- [ ] Read `forgeos/wrappers/oh-my-pi/profiles/runpod-vllm.yaml`.
- [ ] Read `forgeos/wrappers/pi-contract-wrapper/wrapper.contract.yaml`.

## Phase 2: Required contracts

- [ ] Confirm `contracts/schema.sql` exists.
- [ ] Confirm `contracts/openapi.yaml` exists.
- [ ] Confirm `contracts/arazzo.yaml` exists.
- [ ] Confirm `contracts/cobra.yaml` exists.

If any contract is missing, generate a starter contract before implementation.

## Phase 3: Gateway

- [ ] Confirm `forgeos/tool-gateway/tools.json` exists.
- [ ] Confirm `forgeos/tool-gateway/permissions.yaml` exists.
- [ ] Confirm `forgeos/tool-gateway/openapi.yaml` exists.

## Phase 4: Model backend

- [ ] Configure RunPod vLLM values from `forgeos/integrations/pi-runpod-vllm/.env.example`.
- [ ] Confirm Pi can reach the OpenAI-compatible endpoint.
- [ ] Confirm Pi is using the contract wrapper prompt stack.

## Phase 5: First task

Ask Pi to perform only this first task:

```txt
Read the ForgeOS contracts, compile a context pack, validate the available contracts, and create a task graph. Do not implement application code yet.
```

Expected output:

- `.forgeos/context/pi-contract-context.md`
- `tasks/taskgraph.json`
- progress entry
- validation summary
