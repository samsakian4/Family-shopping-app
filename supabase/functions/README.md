# Edge Functions

Deno/TypeScript functions (14_EDGE_FUNCTIONS.md). Added as the features
that need them are implemented — e.g. `ai-assistant` and `estimate-price`
land alongside the AI and Price Estimation phases, not before.

Every function must:
- Validate the JWT before doing anything else.
- Never return stack traces or secrets in error responses.
- Keep provider API keys as Supabase secrets (`supabase secrets set`),
  never in the Flutter app.
