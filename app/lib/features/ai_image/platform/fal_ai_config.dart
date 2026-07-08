// coverage:ignore-file — compile-time env reads, no logic.
// Fal.ai connection config (T4.3, FR-1.3.4). The API key is a runtime setting
// stored in the SQLCipher KV store (set via Settings) — not a build-time
// define — so it never lives in the repo and can rotate without a rebuild.
// Only the non-secret host + model remain here, supplied at build time via
// --dart-define with safe defaults.

/// Fal.ai REST host. Override only for staging/test routing.
const String falBaseUrl = String.fromEnvironment(
  'RIVENDELL_FAL_BASE_URL',
  defaultValue: 'https://fal.run',
);

/// Fal.ai model id. flux/schnell: fast + cheap; the pictographic prompt forbids
/// text in the image, so schnell's weaker text rendering is irrelevant.
const String falModelId = String.fromEnvironment(
  'RIVENDELL_FAL_MODEL',
  defaultValue: 'fal-ai/flux/schnell',
);
