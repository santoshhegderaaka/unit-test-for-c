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

  copilot -p "
Project uses C with GCC.

Source: $FILE
Target: $TEST_FILE

Task:
- Use assert.h
- Include headers
- main() to run tests
- No production code changes
- Write file directly
" --allow-tool write
done

echo "✅ Unit test generation completed"
