#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./generate-spec-tests.sh <GITHUB_TOKEN>"
  exit 1
fi

GITHUB_TOKEN="$1"

echo "🔐 Logging into GitHub..."
gh auth logout -h github.com || true
echo "$GITHUB_TOKEN" | gh auth login --with-token
gh auth status

echo "📦 Installing Copilot CLI locally..."
npm install @github/copilot

# ✅ THIS IS CRITICAL
export PATH="$PWD/node_modules/.bin:$PATH"

copilot -v

SRC_DIR="src"
TEST_DIR="test"
mkdir -p "$TEST_DIR"

find "$SRC_DIR" -name "*.c" | while read -r FILE; do
  BASENAME=$(basename "$FILE" .c)
  TEST_FILE="$TEST_DIR/${BASENAME}.test.c"


  copilot -p "Project uses plain C compiled with GCC.
Source: $FILE
Target: $TEST_FILE
Task:
- Generate C unit tests using <assert.h>
- Include the corresponding header (.h) file if it exists
- Create a main() function to execute all tests
- Test all public functions
- Stub external dependencies if required
- Do NOT modify production source code
- Write the test file directly to disk
- Keep code ANSI C compatible
- Do NOT use external test frameworks (no Unity, no CMock)
" --allow-tool write
done

echo "✅ Unit test generation completed"
