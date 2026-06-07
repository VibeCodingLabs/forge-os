# Vercel AI SDK Middleware Contract

This contract defines how ForgeOS should use Vercel AI SDK middleware for normalized model calls.

## Docs validation notes

Context7 confirms that AI SDK supports:

- provider registries
- custom providers
- OpenAI-compatible providers
- `wrapLanguageModel`
- middleware hooks such as `wrapGenerate` and `wrapStream`
- `generateText`
- provider metadata through provider options
- telemetry metadata

OpenAPI Generator docs confirm generation and validation flows through generator names, config files, and additional properties.

## Middleware stack order

Use this order:

1. request identity middleware
2. policy middleware
3. cache lookup middleware
4. knowledge-context injection middleware
5. telemetry middleware
6. provider execution
7. response normalization middleware
8. usage accounting middleware
9. cache write middleware
10. route decision logging middleware

## Required middleware responsibilities

### request identity

Attach:

- request_id
- trace_id
- agent_id
- task_id
- route_id
- user_workspace_id when available

### policy

Validate:

- model allowed
- provider enabled
- capability requested
- budget policy
- required context size
- tool-call requirement
- structured-output requirement

### cache lookup

Cache key should include:

- model id
- provider id
- normalized prompt hash
- tool schema hash
- knowledge context hash
- generation settings hash

### knowledge-context injection

Inject curated knowledge-base snippets before the model call when:

- task requires repo knowledge
- agent profile requests expert context
- matching KB chunks pass relevance threshold

### telemetry

Record:

- provider
- model
- route decision
- latency
- tokens when returned by provider
- cache hit
- context injection status
- fallback chain
- status
- errors

### response normalization

Normalize provider output into:

- text
- structured object when available
- tool calls when available
- usage metrics
- provider metadata
- finish reason
- warnings

## TypeScript implementation target

The implementation should create these files:

```txt
apps/gateway/src/ai/registry.ts
apps/gateway/src/ai/middleware/cache.ts
apps/gateway/src/ai/middleware/context.ts
apps/gateway/src/ai/middleware/policy.ts
apps/gateway/src/ai/middleware/telemetry.ts
apps/gateway/src/ai/router.ts
apps/gateway/src/ai/usage.ts
```

## Required tests

- cache hit avoids provider execution when allowed
- context injection adds KB snippets with source metadata
- policy blocks models that do not satisfy required capabilities
- fallback selects next eligible ranked model
- usage event is recorded after success
- usage event is recorded after error
- route decision includes an explanation
