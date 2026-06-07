# LLM Routing Policy Contract

## Default policy

Use `free_first` unless a task explicitly requires another budget mode.

## Selection inputs

The router must receive:

- requested_capability
- context_required_tokens
- tool_call_required
- structured_output_required
- streaming_preferred
- budget_policy

## Hard filters

A model is eligible only when:

- the provider is enabled
- the model is enabled
- the model is available or preview
- the context window meets the request
- tool support exists when required
- structured output support exists when required
- daily and monthly free windows still have room when using free-first mode

## Scoring

Each score is normalized from 0.0 to 1.0.

The composite route score should combine:

- free quota score
- reliability score
- speed score
- quality score
- context score
- tool-use score

## Fallback triggers

Fallback when:

- free window is exhausted
- provider is unavailable
- model is unavailable
- requested context does not fit
- required tool behavior is unavailable
- structured output is unavailable
- latency threshold is exceeded
- error threshold is exceeded

## Fallback rules

- maximum fallback attempts: 4
- avoid recently failed models for 15 minutes
- preserve required capabilities
- explain every route decision
- record the fallback chain

## Daily and monthly display

The UI or CLI must show:

- requests used today
- requests remaining today
- requests used this month
- requests remaining this month
- token usage when known
- percent used
- last verified provider fact timestamp
