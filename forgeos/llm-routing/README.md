# ForgeOS LLM Routing

This directory defines contracts for normalized model discovery, usage accounting, capability ranking, and fallback routing for ForgeOS agents.

Provider facts change often. Treat checked-in provider data as a seed and refresh it from provider documentation or provider APIs before production use.

## Goals

- Normalize provider and model metadata.
- Track usage by day and month.
- Track capability tags, context windows, limits, latency, and observed quality.
- Rank free models for each task type.
- Select fallback models when a model is unavailable, exhausted, slow, or failing.
- Provide middleware contracts for cache and knowledge-base context injection.
- Provide acceptance criteria, definition of done, style, linting, and testing standards.

## Files

```txt
forgeos/llm-routing/contracts/schema.sql
forgeos/llm-routing/contracts/openapi.yaml
forgeos/llm-routing/contracts/model-matrix.schema.json
forgeos/llm-routing/contracts/provider-discovery.matrix.yaml
forgeos/llm-routing/contracts/routing-policy.yaml
forgeos/llm-routing/contracts/arazzo.yaml
forgeos/llm-routing/middleware/vercel-ai-sdk-middleware.contract.md
forgeos/llm-routing/kb/private-kb.contract.md
forgeos/llm-routing/standards/ACCEPTANCE_CRITERIA.md
forgeos/llm-routing/standards/DEFINITION_OF_DONE.md
forgeos/llm-routing/standards/STYLE_GUIDE.md
forgeos/llm-routing/standards/LINT_TEST_STANDARD.md
forgeos/llm-routing/prompts/pi-llm-routing-task.md
```
