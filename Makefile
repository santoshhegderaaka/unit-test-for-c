CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g
SRC_DIR = src
BUILD_DIR = build

# Source files (exclude test files)
SOURCES = $(filter-out $(SRC_DIR)/test_%.c, $(wildcard $(SRC_DIR)/*.c))
OBJECTS = $(SOURCES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)

# Test files
TEST_SOURCES = $(wildcard $(SRC_DIR)/test_*.c)
TEST_TARGETS = $(TEST_SOURCES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%)

.PHONY: all clean setup test help

all: setup $(OBJECTS)

setup:
	@mkdir -p $(BUILD_DIR)

# Compile source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Build test executables
$(BUILD_DIR)/test_%: $(SRC_DIR)/test_%.c $(OBJECTS)
	$(CC) $(CFLAGS) $(OBJECTS) $< -o $@

# Run all tests
test: setup $(TEST_TARGETS)
	@echo "Running tests..."
	@for test in $(TEST_TARGETS); do \
		echo "\n--- Running $$test ---"; \
		$$test; \
	done

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Available targets:"
	@echo "  all    - Build all object files"
	@echo "  test   - Build and run all unit tests"
	@echo "  clean  - Remove build directory"
	@echo "  help   - Show this help message"