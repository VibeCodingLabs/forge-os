# Normalized Model Matrix Contract

Every provider model record must normalize these fields:

## Provider fields

- provider_id
- display_name
- docs_url
- connection_modes
- ai_sdk_package
- openai_compatible
- last_verified_at

## Model identity fields

- model_id
- provider_model_id
- display_name
- status
- free_tier
- open_weights
- model_card_url
- docs_url
- verification_source

## Capability fields

- input_modalities
- output_modalities
- capabilities
- parameter_count_text
- parameter_count_billions
- context_window_tokens
- max_output_tokens
- supports_streaming
- supports_tools
- supports_structured_output
- supports_json_mode
- supports_reasoning_tokens
- supports_cached_input_tokens

## Limit fields

- requests_per_minute
- requests_per_day
- requests_per_month
- tokens_per_minute
- tokens_per_day
- tokens_per_month
- concurrent_requests
- reset_timezone
- source_url
- last_verified_at

## Score fields

Each score is normalized from 0.0 to 1.0.

- quality_score
- speed_score
- free_quota_score
- context_score
- tool_use_score
- reliability_score
- composite_score

## Required warning

Never assume free-tier limits are permanent. Refresh and timestamp provider facts before routing production workloads.
