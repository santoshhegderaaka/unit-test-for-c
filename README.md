# C Embedded Modules Project

A C project with embedded-style modules for task management and queue operations.

## Project Structure

```
C_unit_test/
├── src/                    # Source code
│   ├── task_manager.h/c   # Task management module
│   └── queue.h/c          # Circular queue implementation
├── Makefile              # Build configuration
└── README.md
```

## Modules

### Task Manager
- Create, delete, and manage tasks
- Task states: READY, RUNNING, BLOCKED, SUSPENDED
- Priority and stack size management
- Similar to FreeRTOS task management

### Queue
- Circular buffer implementation
- Thread-safe operations
- Configurable size up to 32 elements
- Standard enqueue/dequeue operations

## Building

### Build all modules:
```bash
make all
```

### Clean build files:
```bash
make clean
```

## AI Code Assistance Integration

This project can be enhanced with AI-powered code assistance tools:

### GitHub models API
You are an expert C developer and a meticulous test engineer.",
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
    "- The output must be ONLY the complete C code of the test file (no explanations)."

### Steps to follow
- Create a new GitHub repository to store the C source code, Jenkinsfile, and test-generation scripts.

- Add a Jenkinsfile to the repository that defines all pipeline stages such as checkout, unit test generation, compilation, test execution, coverage reporting, and deployment.

- Create a generate-c-tests.mjs script that is executed by the Jenkins pipeline; this script calls the GitHub Models API by sending a prompt and receives generated C unit test cases as a response.

- Open Jenkins and create a new Pipeline job that points to the GitHub repository and uses the Jenkinsfile for execution.

- In Jenkins, create and configure secrets to securely store the GitHub access token required for calling the GitHub Models API.

- Run the Jenkins pipeline and verify that each stage executes successfully, unit test files are generated in the workspace, and build, test, and coverage results are visible in Jenkins.
