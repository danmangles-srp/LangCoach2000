// coverage:ignore-file — compile-time env reads, no logic.
// Fal.ai connection config (T4.3, FR-1.3.4). All three are supplied at build
// time via --dart-define so nothing secret or deploy-specific lives in the
// repo. Defaults make the app run (and fail clearly at the first generation
// attempt) when a key isn't defined.

/// Fal.ai API key. REQUIRED at runtime for image generation; empty until a real
/// key is passed via `--dart-define=RIVENDELL_FAL_KEY=...`. The service throws
/// a clear StateError on an empty key rather than silently failing.
const String falApiKey = String.fromEnvironment('RIVENDELL_FAL_KEY');

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
