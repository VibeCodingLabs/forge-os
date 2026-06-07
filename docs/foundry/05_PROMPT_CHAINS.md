# Forge Foundry Prompt Chains

## 1. Purpose

Prompt chains are repeatable instructions for agents and coding agents.

They should be used to:

- research libraries
- inspect docs
- plan capture jobs
- normalize raw artifacts
- generate contracts
- generate tools
- review security risks
- update the LLM wiki
- package monetizable deliverables

A prompt chain is not just a single prompt. It is a staged workflow with inputs, outputs, validation gates, and expected artifacts.

## 2. Global Prompt Rules

Every prompt chain must include:

1. Goal
2. Inputs
3. Constraints
4. Required source checks
5. Required outputs
6. Validation steps
7. Observability event
8. Files to update
9. Failure handling

## 3. Chain: Research Official Docs

### Goal

Verify current APIs, commands, versions, and recommended practices before generating code.

### Prompt

```text
You are the Scout agent. Research the official documentation for the following libraries/tools: {{tools}}.

Use official docs first. Prefer primary sources over blog posts. For each tool, extract:

- current install command
- core API concepts
- minimum working example
- version-specific gotchas
- security warnings
- integration notes for Forge Foundry
- links/citations

Return:

1. concise findings
2. exact commands
3. architecture implications
4. risks
5. recommended implementation changes
```

### Outputs

- `raw/research/{{topic}}.md`
- `wiki/research/{{topic}}.md`
- observability event: `research.docs.completed`

## 4. Chain: Capture Planning

### Goal

Create a safe capture plan for an authorized URL or app.

### Prompt

```text
You are the Capture Planner agent. Create a capture plan for {{target_url}}.

Rules:
- Only plan capture if target is authorized.
- Do not include credential theft, bypass, spam, or evasion steps.
- Identify safe browser flows.
- Identify likely API/XHR endpoints.
- Define redaction requirements.
- Define capture artifacts.
- Define stop conditions.

Return:

1. authorization checklist
2. capture mode recommendation
3. Playwright steps
4. mitmdump/HAR strategy
5. artifact paths
6. redaction plan
7. SQLite mirror fields
8. validation checklist
```

### Outputs

- `generated/capture-plans/{{target_slug}}.md`
- `raw/manifests/{{target_slug}}.capture.json`
- observability event: `capture.plan.created`

## 5. Chain: HAR / Flow Normalization

### Goal

Turn raw HAR/mitmproxy flow data into structured endpoint records.

### Prompt

```text
You are the Normalizer agent. Normalize this capture artifact: {{artifact_path}}.

Tasks:
- Parse requests and responses.
- Remove duplicate/noisy static assets.
- Group by host, path, method, and response type.
- Identify likely API endpoints.
- Infer path parameters.
- Infer query parameters.
- Infer request and response JSON shapes.
- Flag sensitive fields for redaction.
- Produce endpoint rows suitable for SQLite import.

Return:

1. endpoint catalog
2. ignored/noisy paths
3. inferred schemas
4. redaction warnings
5. import SQL or JSON rows
6. validation checklist
```

### Outputs

- `generated/normalized/{{capture_id}}.endpoints.json`
- SQLite endpoint rows
- observability event: `capture.normalized`

## 6. Chain: OpenAPI Compiler

### Goal

Generate OpenAPI 3.1 from endpoint mirror rows.

### Prompt

```text
You are the Contract Compiler agent. Generate an OpenAPI 3.1 spec from the mirror records for {{site_id}}.

Rules:
- Include only endpoints with sufficient evidence.
- Include source capture references in operation extensions.
- Mark inferred schemas clearly.
- Avoid inventing undocumented auth flows.
- Include examples where available.
- Use stable operation IDs.

Return:

1. OpenAPI YAML
2. unresolved questions
3. endpoint confidence scores
4. validation command
5. source mapping table
```

### Outputs

- `generated/openapi/{{site_slug}}.openapi.yaml`
- `generated/reports/{{site_slug}}.openapi-report.md`
- observability event: `compiler.openapi.completed`

## 7. Chain: Zod + Pydantic Schema Mirror

### Goal

Generate typed validators from OpenAPI or mirror schemas.

### Prompt

```text
You are the Schema Compiler agent. Generate Zod and Pydantic models for {{contract_path}}.

Requirements:
- Use shared names where possible.
- Preserve optional vs required fields.
- Add examples.
- Add validation tests.
- Document unsupported schema features.

Return:

1. generated file list
2. Zod code
3. Pydantic code
4. tests
5. validation commands
6. gotchas
```

### Outputs

- `generated/zod/{{site_slug}}/`
- `generated/pydantic/{{site_slug}}/`
- observability event: `compiler.schemas.completed`

## 8. Chain: Cobra CLI Generator

### Goal

Generate a Go CLI for querying mirrors or calling approved API wrappers.

### Prompt

```text
You are the CLI Generator agent. Generate a Cobra CLI package for {{site_slug}}.

The CLI must:
- query SQLite mirror by default
- expose endpoint catalog commands
- expose example replay commands only when approved
- include config loading
- include JSON output
- include shell completions
- log tool calls to Forge observability

Return:

1. command tree
2. generated Go files
3. README usage examples
4. tests
5. build command
```

### Outputs

- `generated/cobra/{{site_slug}}/`
- observability event: `compiler.cobra.completed`

## 9. Chain: FastMCP Tool Generator

### Goal

Expose mirror queries and generated operations as MCP tools.

### Prompt

```text
You are the MCP Generator agent. Generate a FastMCP server for {{site_slug}}.

Tools must:
- query local SQLite mirrors first
- return compact structured responses
- expose artifacts as resources, not giant inline blobs
- log tool calls
- enforce authorization policies
- include examples

Return:

1. FastMCP server code
2. tool list
3. resource list
4. prompt list
5. test commands
```

### Outputs

- `generated/mcp/{{site_slug}}/`
- observability event: `compiler.mcp.completed`

## 10. Chain: Mirror-First Agent Review

### Goal

Verify an agent is using local mirrors and generated tools instead of raw web context.

### Prompt

```text
You are the Analyst agent. Review the agent run {{run_id}} for mirror-first compliance.

Check:
- Did it query SQLite first?
- Did it use generated tools?
- Did it read raw artifacts unnecessarily?
- Did it request live capture without approval?
- Did it log model/tool calls?
- Did it minimize context?

Return:

1. compliance verdict
2. evidence table
3. violations
4. fixes
5. eval score
```

### Outputs

- `generated/reports/{{run_id}}.mirror-first-review.md`
- observability event: `eval.mirror_first.completed`

## 11. Chain: LLM Wiki Update

### Goal

Update wiki pages after a capture/compiler/agent run.

### Prompt

```text
You are the Archivist agent. Update the LLM wiki from {{run_id}}.

Create or update:
- project page
- site/API page
- endpoint pages
- workflow page
- artifact index
- decision notes
- next actions

Rules:
- Include source artifact links.
- Use YAML frontmatter.
- Mark generated pages as draft.
- Do not claim unverified facts.
- Create graph edge suggestions.

Return:

1. page list
2. markdown pages
3. wiki edge rows
4. review checklist
```

### Outputs

- `wiki/generated/`
- SQLite `wiki_pages`
- SQLite `wiki_edges`
- observability event: `wiki.update.completed`

## 12. Chain: Monetization Package Generator

### Goal

Turn a successful capture-to-contract run into a sellable deliverable.

### Prompt

```text
You are the Product Strategist agent. Package {{site_slug}} into a monetizable service deliverable.

Create:
- client-facing summary
- technical scope
- deliverables
- pricing angle
- risk notes
- demo script
- upsell opportunities
- implementation plan

Avoid hype. Be specific, professional, and outcome-focused.
```

### Outputs

- `generated/monetization/{{site_slug}}.package.md`
- observability event: `monetization.package.generated`

## 13. Chain: Security Review

### Goal

Review captures, generated tools, and agent workflows for safety and compliance.

### Prompt

```text
You are the Security Engineer agent. Review {{artifact_or_run_id}}.

Check:
- authorization scope
- secrets in HAR/flows
- cookies/tokens
- PII
- unsafe generated replay commands
- missing redaction
- broad permissions
- live network calls
- logs containing sensitive bodies

Return:

1. risk summary
2. findings table
3. severity
4. required remediations
5. approval/block verdict
```

### Outputs

- `generated/security/{{id}}.review.md`
- observability event: `security.review.completed`

## 14. Prompt Chain Gotchas

- Never ask an agent to blindly trust raw captures.
- Never generate replay tools without policy gates.
- Never inline huge raw artifacts into prompts.
- Never let prompt chains overwrite canonical docs without review.
- Never treat inferred schemas as official truth.
- Always preserve uncertainty.
- Always log the compiler/model/tool run.
