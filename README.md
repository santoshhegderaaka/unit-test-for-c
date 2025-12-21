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

### GitHub Copilot
- AI-powered code suggestions and completions
- Chat functionality for code explanations
- Available in VS Code, JetBrains IDEs, and other editors
- Pricing: $10/month (Individual), $19/month (Business)

### Bito AI
- Automated code review and analysis
- AI-powered code generation and optimization
- Integration with popular IDEs and Git workflows
- Custom pricing plans available
