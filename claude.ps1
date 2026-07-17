# 1. Clear out the default API key variables to avoid header conflicts
$env:ANTHROPIC_API_KEY="bearer-bypass-token"
$env:ANTHROPIC_BASE_URL="http://localhost:4000"
$env:ANTHROPIC_AUTH_TOKEN="bearer-bypass-token"

# 2. Force it to default to your high-effort profile on launch
$env:ANTHROPIC_MODEL="claude-sonnet-4-6"

# 3. Always launch directly into Auto Mode
claude --permission-mode auto --resume 539ea23c-4940-4816-80c8-a89579598f94