# 1. Clear out the default API key variable to avoid header conflicts
$env:ANTHROPIC_API_KEY=""

# 2. Point the base URL to your running LiteLLM server
$env:ANTHROPIC_BASE_URL="http://localhost:4000"

# 3. Provide a dummy Bearer token to satisfy the CLI's internal local validation
$env:ANTHROPIC_AUTH_TOKEN="bearer-bypass-token"

# 4. Launch the tool
claude --resume 539ea23c-4940-4816-80c8-a89579598f94

