#!/bin/bash
set -e

# -----------------------------
# 0. Argument / Env Var Handling
# -----------------------------
# Use argument $1 if provided, otherwise check for env var COPILOT_TOKEN
COPILOT_TOKEN="${1:-$COPILOT_TOKEN}"

# Use argument $2 if provided, otherwise check for env var PUSH_TOKEN
PUSH_TOKEN="${2:-$PUSH_TOKEN}"

if [ -z "$COPILOT_TOKEN" ] || [ -z "$PUSH_TOKEN" ]; then
  echo "❌ Error: Missing Tokens."
  echo "You must provide tokens either as arguments or environment variables."
  echo ""
  echo "Usage Option 1 (Args): ./generate-c-tests.sh <COPILOT_TOKEN> <PUSH_TOKEN>"
  echo "Usage Option 2 (Env):  export COPILOT_TOKEN=...; export PUSH_TOKEN=...; ./generate-c-tests.sh"
  exit 1
fi

# Ensure dependencies are present
for cmd in gh jq curl git; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ Error: '$cmd' is not installed. Please install it."
    exit 1
  fi
done

# -----------------------------
# Config
# -----------------------------
SRC_DIR="src"
TEST_DIR="test"

mkdir -p "$TEST_DIR"

# -----------------------------
# 1. Login using COPILOT_TOKEN (Read Access)
# -----------------------------
echo "🔐 Logging in to generate tests..."
gh auth logout -h github.com -y >/dev/null 2>&1 || true
echo "$COPILOT_TOKEN" | gh auth login --with-token
gh auth status

# -----------------------------
# 2. Obtain Internal Copilot Token
# -----------------------------
# Exchange the CLI token for a Copilot-specific token to use the API directly.
echo "🔄 Exchanging token for Copilot API access..."

GH_TOKEN=$(gh auth token)
COPILOT_TOKEN_RESP=$(curl -s -X GET https://api.github.com/copilot_internal/v2/token \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/json" \
  -H "Editor-Version: vscode/1.86.0" \
  -H "Editor-Plugin-Version: copilot/1.166.0" \
  -H "User-Agent: GitHubCopilot/1.166.0")

COPILOT_ACCESS_TOKEN=$(echo "$COPILOT_TOKEN_RESP" | jq -r '.token')

if [ "$COPILOT_ACCESS_TOKEN" == "null" ] || [ -z "$COPILOT_ACCESS_TOKEN" ]; then
    echo "❌ Failed to get Copilot token. Ensure the provided token has Copilot access."
    echo "Debug Info: $COPILOT_TOKEN_RESP"
    exit 1
fi

# -----------------------------
# 3. Define Generator Function
# -----------------------------
generate_test_file() {
    local src_file="$1"
    local test_file="$2"
    local content=$(cat "$src_file")

    # Construct the JSON payload for the AI
    local payload=$(jq -n --arg content "$content" --arg file "$src_file" '{
        model: "gpt-4",
        messages: [
            {
                role: "system", 
                content: "You are an expert C programmer. Task: Write a unit test file.\nRules:\n1. Use <assert.h> for assertions.\n2. Create a main() function to execute tests.\n3. Include the source header if implied.\n4. Mock external dependencies if complex.\n5. Output ONLY raw C code. No markdown."
            },
            {
                role: "user", 
                content: ("Generate a C unit test file for: " + $file + "\n\nCode:\n" + $content)
            }
        ],
        temperature: 0.1
    }')

    # Send request to Copilot API
    local response=$(curl -s -X POST https://api.githubcopilot.com/chat/completions \
        -H "Authorization: Bearer $COPILOT_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -H "Editor-Version: vscode/1.86.0" \
        -d "$payload")

    # Parse response
    local generated_code=$(echo "$response" | jq -r '.choices[0].message.content')

    if [ "$generated_code" == "null" ]; then
        echo "   ⚠️  Error generating for $src_file"
        return
    fi

    # Clean up markdown if the AI added it (e.g. ```c ... ```)
    echo "$generated_code" | sed 's/^```c//g' | sed 's/^```//g' > "$test_file"
}

# -----------------------------
# 4. Generate Tests Loop
# -----------------------------
echo "🚀 Starting C test generation..."

find "$SRC_DIR" -type f -name "*.c" ! -name "*_test.c" | while read -r FILE
do
  BASENAME=$(basename "$FILE" .c)
  TEST_FILE="$TEST_DIR/${BASENAME}_test.c"

  echo "----------------------------------------"
  echo "Source: $FILE"
  echo "Output: $TEST_FILE"
  
  generate_test_file "$FILE" "$TEST_FILE"
done

echo "✅ Test generation completed."

# -----------------------------
# 5. Switch auth → Login using PUSH_TOKEN (Write Access)
# -----------------------------
echo "🔄 Switching GitHub auth for push..."

gh auth logout -h github.com -y >/dev/null 2>&1 || true
echo "$PUSH_TOKEN" | gh auth login --with-token
gh auth status

# CRITICAL: force git to use this token for HTTPS operations
gh auth setup-git

# -----------------------------
# 6. Git commit & push
# -----------------------------
echo "Checking for git changes..."

if [ -n "$(git status --porcelain)" ]; then
  echo "Changes detected. Committing..."

  # Set git identity for CI
  git config user.name "copilot-bot"
  git config user.email "bot@local"

  git add "$TEST_DIR/"
  git commit -m "test: auto-generate C unit tests using Copilot"

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "Pushing to branch: $CURRENT_BRANCH"

  git push origin "$CURRENT_BRANCH"

  echo "✅ Changes committed and pushed successfully"
else
  echo "🤷 No changes to commit"
fi