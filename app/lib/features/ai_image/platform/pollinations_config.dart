// coverage:ignore-file — compile-time env reads, no logic.
// Pollinations image-generation connection config (FR-1.3.4). Pollinations is
// keyless on the free tier — no API key, no Settings entry — so the only knobs
// here are the non-secret host + model, supplied at build time via
// --dart-define with safe defaults.

/// Pollinations image host. Override only for staging/test routing.
const String pollinationsBaseUrl = String.fromEnvironment(
  'RIVENDELL_POLLINATIONS_BASE_URL',
  defaultValue: 'https://image.pollinations.ai',
);

/// Pollinations model id. `flux`: solid quality on the free tier; `turbo` is
/// the faster, lower-quality alternative.
const String pollinationsModel = String.fromEnvironment(
  'RIVENDELL_POLLINATIONS_MODEL',
  defaultValue: 'flux',
);
