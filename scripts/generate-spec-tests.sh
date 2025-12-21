#!/bin/bash
set -e

# ----------------------------------
# Preconditions
# ----------------------------------
if [ -z "$1" ]; then
  echo "Usage: ./generate-c-tests.sh <GITHUB_TOKEN>"
  exit 1
fi

GITHUB_TOKEN="$1"

# ----------------------------------
# IMPORTANT NOTES
# ----------------------------------
echo "⚠️  NOTE:"
echo "⚠️  GitHub Copilot CLI works ONLY in interactive shells."
echo "⚠️  This script will NOT work in Jenkins or non-interactive CI."
echo ""

# ----------------------------------
# GitHub authentication
# ----------------------------------
echo "🔐 Logging into GitHub..."
gh auth logout -h github.com || true
echo "$GITHUB_TOKEN" | gh auth login --with-token
gh auth status

# ----------------------------------
# Install Copilot CLI (latest)
# ----------------------------------

#echo "📦 Installing GitHub Copilot CLI..."
#npm uninstall -g @github/copilot >/dev/null 2>&1 || true
#npm install -g @github/copilot
#copilot -v

# ----------------------------------
# Project config
# ----------------------------------
SRC_DIR="src"
TEST_DIR="test"

mkdir -p "$TEST_DIR"

# ----------------------------------
# Generate unit tests for C files
# ----------------------------------
find "$SRC_DIR" -type f -name "*.c" | while read -r FILE
do
  BASENAME=$(basename "$FILE" .c)
  TEST_FILE="$TEST_DIR/${BASENAME}.test.c"

  echo "----------------------------------------"
  echo "Source: $FILE"
  echo "Test:   $TEST_FILE"
  echo "----------------------------------------"

  copilot -p "
Project uses plain C compiled with GCC.

Source file: $FILE
Target test file: $TEST_FILE

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

echo ""
echo "✅ C unit test generation completed"
echo "📂 Tests created under ./test"
