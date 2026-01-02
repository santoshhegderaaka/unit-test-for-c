#!/usr/bin/env node
/**
 * Generate ANSI-C unit tests (assert.h, no external frameworks) for a C source file
 * using GitHub Models Inference API (official).
 *
 * Requirements enforced via prompt:
 * - ANSI C compatible
 * - Use <assert.h>
 * - Include corresponding header if it exists
 * - Create main() that runs all tests
 * - Test all public functions
 * - Stub external dependencies if required
 * - Do NOT modify production source code
 * - Write test file to disk
 *
 * Usage:
 *   node generate-c-tests.mjs --src src/task_manager.c --out tests/test_task_manager.c
 * Optional:
 *   node generate-c-tests.mjs --src src/task_manager.c --hdr src/task_manager.h --out tests/test_task_manager.c
 *
 * Env:
 *   GITHUB_TOKEN  (PAT/GitHub App token with models:read permission)
 *   GH_MODEL      (optional, default: openai/gpt-4.1)
 */

import fs from "node:fs";
import path from "node:path";
import process from "node:process";

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const k = a.slice(2);
      const v = argv[i + 1] && !argv[i + 1].startsWith("--") ? argv[++i] : true;
      args[k] = v;
    }
  }
  return args;
}

function fileExists(p) {
  try {
    return fs.statSync(p).isFile();
  } catch {
    return false;
  }
}

function ensureDirForFile(filePath) {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
}

/**
 * Extracts code from a response that may include markdown fences.
 * Prefers a ```c block; else falls back to any fenced block; else raw text.
 */
function extractCTestCode(text) {
  if (!text) return "";
  const cBlock = text.match(/```c\s*([\s\S]*?)```/i);
  if (cBlock && cBlock[1]) return cBlock[1].trim();

  const anyBlock = text.match(/```[a-z0-9_-]*\s*([\s\S]*?)```/i);
  if (anyBlock && anyBlock[1]) return anyBlock[1].trim();

  return text.trim();
}

async function callGitHubModels({ token, model, messages, temperature = 0.2, max_tokens = 3500 }) {
  // Official endpoint as shown in GitHub Models inference docs. :contentReference[oaicite:2]{index=2}
  console.log(`Calling GitHub Models API with model=${model} temperature=${temperature} max_tokens=${max_tokens} token=${token}`);
  const url = "https://models.github.ai/inference/chat/completions";

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Accept": "application/vnd.github+json",
      "Authorization": `Bearer ${token}`,
      "X-GitHub-Api-Version": "2022-11-28",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      messages,
      temperature,
      max_tokens,
      stream: false,
    }),
  });

  const bodyText = await res.text();
  if (!res.ok) {
    let msg = bodyText;
    try {
      const j = JSON.parse(bodyText);
      msg = j?.message || j?.error?.message || bodyText;
    } catch {}
    throw new Error(`GitHub Models API failed (${res.status}): ${msg}`);
  }

  let json;
  try {
    json = JSON.parse(bodyText);
  } catch (e) {
    throw new Error(`Failed to parse JSON response: ${e.message}\nRaw:\n${bodyText}`);
  }

  const content = json?.choices?.[0]?.message?.content ?? "";
  return content;
}

function buildSystemPrompt() {
  return [
    "You are an expert C developer and a meticulous test engineer.",
    "",
    "Generate a single C test file that follows these rules exactly:",
    "- ANSI C compatible (no C99-only features if avoidable; do not require external frameworks)",
    "- Use <assert.h> only for assertions (no Unity/CMock/CuTest/etc.)",
    "- Include the corresponding production header (.h) if it exists (use #include \"...\"), otherwise explain via comment why not",
    "- Create a main() function that executes all tests and returns 0 on success",
    "- Test all PUBLIC functions (functions intended for external use); do not test static/private internals directly",
    "- Stub/mock external dependencies if required (by providing dummy implementations inside the test file)",
    "- Do NOT modify production source code; do not assume changes in src/",
    "- Keep tests deterministic (no sleeps, no timing dependent checks)",
    "- The output must be ONLY the complete C code of the test file (no explanations).",
  ].join("\n");
}

function buildUserPrompt({ srcPath, srcText, hdrPath, hdrText, outPath }) {
  const hdrSection = hdrText
    ? `\n\n=== Header file (${hdrPath}) ===\n${hdrText}\n`
    : `\n\n(No header file was provided/found. If a header is required, infer it cautiously from the source and include what exists.)\n`;

  return [
    "Generate ANSI-C unit tests for the following C production source.",
    "Write tests in a single .c file.",
    `The test file should be saved as: ${outPath}`,
    "",
    "Project constraints:",
    "- Compiled with GCC",
    "- No external unit-test framework",
    "",
    `=== Production source (${srcPath}) ===`,
    srcText,
    hdrSection,
    "",
    "Important: Identify public functions by reading the header if present; otherwise infer 'public' as non-static functions meant to be used externally.",
    "If the source depends on external symbols, provide stubs in the test file.",
    "Output ONLY valid C code.",
  ].join("\n");
}

async function main() {
  const args = parseArgs(process.argv);
  console.log(`${JSON.stringify(args)}`);
  //const token = args.token;
  const srcPath = args.src;
  const outPath = args.out || "test/test_generated.test.c";
  const hdrPathArg = args.hdr;

  if (!srcPath) {
    console.error("Missing --src. Example: node generate-c-tests.mjs --src src/task_manager.c --out test/test_task_manager.test.c");
    process.exit(2);
  }

  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    console.error("Missing env GITHUB_TOKEN (needs models:read permission).");
    process.exit(2);
  }

  const model = process.env.GH_MODEL || "GPT-4.1";

  if (!fileExists(srcPath)) {
    console.error(`Source not found: ${srcPath}`);
    process.exit(2);
  }

  const srcText = fs.readFileSync(srcPath, "utf8");

  // Try to locate header:
  let hdrPath = null;
  let hdrText = null;

  if (hdrPathArg) {
    if (!fileExists(hdrPathArg)) {
      console.error(`Header not found: ${hdrPathArg}`);
      process.exit(2);
    }
    hdrPath = hdrPathArg;
    hdrText = fs.readFileSync(hdrPathArg, "utf8");
  } else {
    // Heuristic: same base name as src, same folder, .h extension
    const guess = srcPath.replace(/\.c$/i, ".h");
    if (guess !== srcPath && fileExists(guess)) {
      hdrPath = guess;
      hdrText = fs.readFileSync(guess, "utf8");
    }
  }

  const messages = [
    { role: "system", content: buildSystemPrompt() },
    {
      role: "user",
      content: buildUserPrompt({
        srcPath,
        srcText,
        hdrPath: hdrPath || "(none)",
        hdrText,
        outPath,
      }),
    },
  ];

  const raw = await callGitHubModels({
    token,
    model,
    messages,
    temperature: 0.2,
    max_tokens: 3500,
  });

  const cCode = extractCTestCode(raw);

  // Basic safety checks: must contain assert.h and main().
  if (!/#include\s*<assert\.h>/.test(cCode)) {
    console.error("Model output did not include <assert.h>. Refusing to write file.");
    process.exit(1);
  }
  if (!/\bint\s+main\s*\(/.test(cCode)) {
    console.error("Model output did not include main(). Refusing to write file.");
    process.exit(1);
  }

  ensureDirForFile(outPath);
  fs.writeFileSync(outPath, cCode + "\n", "utf8");
  console.log(`✅ Wrote generated tests to: ${outPath}`);
}

main().catch((err) => {
  console.error("❌ Failed:", err?.message || err);
  process.exit(1);
});
