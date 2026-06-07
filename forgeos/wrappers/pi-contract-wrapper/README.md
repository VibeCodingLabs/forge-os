# Pi Contract Wrapper for ForgeOS

This wrapper makes `pi` operate as a contract-first coding agent for ForgeOS.

The wrapper does not trust the model to decide project shape. It compiles contracts into an execution context, routes actions through named ForgeOS tools, and validates output before progress is marked complete.

## Goal

```txt
Pi agent
  -> ForgeOS wrapper context compiler
  -> schema contracts + OpenAPI specs + Arazzo workflows
  -> Cobra/Go CLI tools
  -> OpenAPI Generator SDK/codegen
  -> validation report
  -> progress update
```

## Contract authority order

The wrapper must treat files in this order of authority:

1. `contracts/schema.sql`
2. `contracts/openapi.yaml`
3. `contracts/arazzo.yaml`
4. `contracts/cobra.yaml`
5. `specs/ARCHITECTURE.md`
6. `tasks/acceptance-criteria.md`
7. `tasks/definition-of-done.md`

If generated code conflicts with a contract, the generated code is wrong.

## Core behavior

The wrapper should make Pi do this before implementation:

1. Load schema contract.
2. Load OpenAPI contract.
3. Load Arazzo workflow contract.
4. Load Cobra/Go CLI contract.
5. Build a task plan from the contracts.
6. Use only declared ForgeOS gateway tools.
7. Generate SDKs/code/commands from contracts.
8. Validate generated output.
9. Update progress.

## Wrapper files

```txt
forgeos/wrappers/pi-contract-wrapper/
  README.md
  wrapper.contract.yaml
  context-pack.md
  tool-policy.yaml
  openapi-generator.matrix.yaml
  cobra.contract.yaml
  arazzo.codegen.yaml
  prompts/pi-contract-system.md
```

## Minimum viable wrapper command

Eventually this should become:

```bash
forge pi run --contract contracts/openapi.yaml --schema contracts/schema.sql --workflow contracts/arazzo.yaml --cobra contracts/cobra.yaml
```

Under the hood it should compile a context pack and pass that to Pi along with the configured RunPod/vLLM endpoint profile.

## Do not rely on prompting alone

The wrapper must enforce structure in four places:

1. Prompt rules
2. Tool schemas
3. Gateway permissions
4. Validation commands

The model can suggest work. The wrapper decides what is valid.
