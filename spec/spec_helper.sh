#!/bin/bash
# ShellSpec Helper - Test configuration and utilities

# Strict mode for tests
set -euo pipefail

# Test directories
# shellcheck disable=SC2155
export SPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2155
export PROJECT_DIR="$(cd "$SPEC_DIR/.." && pwd)"
export TMP_DIR="$PROJECT_DIR/tmp/test_$$"
export FIXTURES_DIR="$SPEC_DIR/fixtures"

# Create isolated test environment
setup_test_env() {
  mkdir -p "$TMP_DIR"
  export HOME="$TMP_DIR/home"
  export PATH="$PROJECT_DIR:$PATH"
  mkdir -p "$HOME"
}

# Cleanup test environment
cleanup_test_env() {
  if [[ -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}

# Mock Docker command for unit tests
mock_docker() {
  export DOCKER_MOCK_MODE=true

  docker() {
    case "$1" in
      "images")
        # Check if --format flag is present
        if [[ "$*" == *"--format"* ]]; then
          # Return formatted output for docker_image_exists
          # Include both the MCP github image and the test registry images
          echo "mcp/github:latest"
          echo "null/test/server:latest"
          echo "test/server:latest"
          echo "test-image:latest"
          echo "test-server-cmd:latest"
        else
          # Return regular table format
          echo "REPOSITORY TAG IMAGE_ID CREATED SIZE"
          echo "mcp/github latest abc123 2 days ago 100MB"
          echo "null/test/server latest def456 1 day ago 50MB"
          echo "test/server latest ghi789 1 day ago 50MB"
          echo "test-image latest jkl012 1 day ago 40MB"
          echo "test-server-cmd latest mno345 1 day ago 45MB"
        fi
        ;;
      "run")
        # Mock docker run - return a fake container ID
        if [[ "$*" == *"-d"* ]]; then
          # Detached mode - return container ID
          echo "abc123def456789"
        else
          # Interactive mode - simulate minimal output
          echo ""
        fi
        ;;
      "logs")
        # Mock docker logs - return MCP server output
        echo '{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","serverInfo":{"name":"test-server"}}}'
        ;;
      "exec")
        # Mock docker exec - return MCP responses based on what's piped in
        local input
        read -r input || true
        if echo "$input" | grep -q '"method":"resources/list"'; then
          echo '{"jsonrpc":"2.0","id":2,"result":{"resources":[{"uri":"file:///test","name":"Test Resource"}]}}'
        elif echo "$input" | grep -q '"method":"tools/list"'; then
          echo '{"jsonrpc":"2.0","id":3,"result":{"tools":[{"name":"test_tool","description":"A test tool"}]}}'
        else
          echo "$input"
        fi
        ;;
      "stop"|"rm")
        # Mock stop/rm - always succeed silently
        return 0
        ;;
      "ps")
        echo "CONTAINER_ID IMAGE COMMAND CREATED STATUS"
        ;;
      "version")
        echo "Docker version 24.0.5, build ced0996"
        ;;
      "info")
        return 0  # Simulate successful docker info
        ;;
      *)
        return 0
        ;;
    esac
  }

  export -f docker
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Assert helpers
assert_file_exists() {
  if [[ ! -f "$1" ]]; then
    echo "Expected file to exist: $1" >&2
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"

  if ! grep -q "$pattern" "$file"; then
    echo "Expected file '$file' to contain: $pattern" >&2
    return 1
  fi
}

assert_output_contains() {
  local output="$1"
  local expected="$2"

  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected output to contain: $expected" >&2
    echo "Got: $output" >&2
    return 1
  fi
}
