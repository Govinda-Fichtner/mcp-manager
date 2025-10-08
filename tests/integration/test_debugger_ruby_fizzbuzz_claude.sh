#!/bin/bash
# Integration test: debugger-ruby with Claude Code using FizzBuzz
# Tests the Ruby-specific debugger MCP server

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_cleanup() {
    echo -e "${BLUE}[CLEANUP]${NC} $1"
}

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="$SCRIPT_DIR/workspace_ruby"
MCP_SERVER_NAME="debugger-ruby-test"

# Cleanup function
cleanup() {
    local exit_code=$?
    log_cleanup "Removing test artifacts..."

    # Remove MCP server from Claude Code
    if claude mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
        log_cleanup "Removing MCP server: $MCP_SERVER_NAME"
        claude mcp remove "$MCP_SERVER_NAME" 2>/dev/null || true
    fi

    # Clean up test workspace
    if [[ -d "$TEST_WORKSPACE" ]]; then
        log_cleanup "Removing test workspace: $TEST_WORKSPACE"
        rm -rf "$TEST_WORKSPACE"
    fi

    if [[ $exit_code -eq 0 ]]; then
        log_success "Cleanup completed successfully"
    fi

    exit $exit_code
}

trap cleanup EXIT INT TERM

# Main test
echo "================================================"
echo "FizzBuzz Integration Test: debugger-ruby + Claude Code"
echo "================================================"
echo ""

# Step 1: Validate Claude CLI
log_step "Step 1: Validating Claude CLI availability"
if ! command -v claude &> /dev/null; then
    log_error "Claude CLI not found in PATH"
    log_info "Install from: https://claude.com/claude-code"
    exit 1
fi

CLAUDE_PATH="$(command -v claude)"
log_success "Claude CLI found: $CLAUDE_PATH"

CLAUDE_VERSION="$(claude --version 2>&1 || echo 'unknown')"
log_info "Claude version: $CLAUDE_VERSION"

# Step 2: Validate Claude functionality
log_step "Step 2: Validating Claude CLI functionality"
if echo "test" | claude -p "respond with 'ok'" &>/dev/null; then
    log_success "Claude CLI is functional"
else
    log_error "Claude CLI is not responding correctly"
    exit 1
fi

# Step 3: Check debugger-ruby image
log_step "Step 3: Validating debugger-ruby Docker image"
if ! docker images | grep -q "debugger-mcp-ruby"; then
    log_error "debugger-mcp-ruby image not found"
    log_info "Run: ./mcp_manager.sh setup debugger-ruby"
    exit 1
fi
log_success "debugger-ruby image found"

# Step 4: Create test workspace
log_step "Step 4: Creating test workspace with FizzBuzz implementation"
mkdir -p "$TEST_WORKSPACE"

# Create Ruby FizzBuzz with bug
cat > "$TEST_WORKSPACE/fizzbuzz.rb" << 'RUBY_CODE'
#!/usr/bin/env ruby
# FizzBuzz implementation with an intentional bug for debugging.
# Bug: divisibility by 5 check is broken (uses 4 instead of 5)

def fizzbuzz(n)
  # Returns FizzBuzz result for number n.
  # - Returns "Fizz" if n is divisible by 3
  # - Returns "Buzz" if n is divisible by 5
  # - Returns "FizzBuzz" if n is divisible by both
  # - Returns the number as string otherwise

  result = ""

  if n % 3 == 0
    result += "Fizz"
  end

  # BUG: This should be n % 5 == 0
  if n % 4 == 0  # <-- INTENTIONAL BUG HERE (line 21)
    result += "Buzz"
  end

  if result.empty?
    result = n.to_s
  end

  result
end

# Run FizzBuzz for numbers 1-15
puts "FizzBuzz Output:"
(1..15).each do |i|
  puts "#{i}: #{fizzbuzz(i)}"
end
RUBY_CODE

chmod +x "$TEST_WORKSPACE/fizzbuzz.rb"
log_success "Created FizzBuzz test file: $TEST_WORKSPACE/fizzbuzz.rb"
log_info "Bug location: Line 21 (uses % 4 instead of % 5)"

# Step 5: Generate MCP configuration
log_step "Step 5: Generating MCP server configuration"
cd "$PROJECT_ROOT"

mcp_config_json="$(./mcp_manager.sh config debugger-ruby --add-json --env-file .env)"
if [[ -z "$mcp_config_json" ]]; then
    log_error "Failed to generate MCP configuration"
    exit 1
fi

log_success "Generated MCP configuration"
log_info "Configuration preview:"
echo "$mcp_config_json" | head -1

# Step 6: Add MCP server to Claude Code
log_step "Step 6: Adding debugger-ruby server to Claude Code"
if ! claude mcp add-json "$MCP_SERVER_NAME" "$mcp_config_json"; then
    log_error "Failed to add MCP server to Claude Code"
    exit 1
fi

log_success "Added MCP server: $MCP_SERVER_NAME"

# Verify server was added
if claude mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
    log_success "Verified MCP server is configured"
else
    log_error "MCP server not found in configuration"
    exit 1
fi

# Step 7: Run Claude Code
log_step "Step 7: Running Claude Code to debug FizzBuzz"
log_info "Test scenario: Ask Claude to find and fix the bug in FizzBuzz"
log_info "Claude should use debugger_mcp tools to inspect the Ruby code"

# Create prompt file
cat > "$TEST_WORKSPACE/debug_prompt.txt" << 'PROMPT'
Analyze the Ruby FizzBuzz implementation in fizzbuzz.rb and find the bug.

The program should:
- Print "Fizz" for numbers divisible by 3
- Print "Buzz" for numbers divisible by 5
- Print "FizzBuzz" for numbers divisible by both
- Print the number otherwise

Use the debugger-ruby-test MCP tools if available to:
1. Start a debugging session for fizzbuzz.rb (Ruby)
2. Set a breakpoint at line 21 (the bug location)
3. Evaluate the expression "n % 5 == 0" vs "n % 4 == 0" for n=5
4. Explain what the bug is and where it is

If debugger tools are not available, just analyze the code manually.

At the end, summarize:
1. What tools you used (if any)
2. What the bug is
3. Where the bug is located (line number)
4. How to fix it
PROMPT

log_info "Prompt: Analyze the FizzBuzz implementation in fizzbuzz.rb and find the bug."

# Run Claude with the prompt and capture output
claude_output_file="$TEST_WORKSPACE/claude_output.txt"
claude_protocol_log="$TEST_WORKSPACE/mcp_protocol.log"

log_info "Running Claude (this may take 30-60 seconds)..."
log_info "MCP protocol debugging enabled"

# Run Claude in the test workspace directory
cd "$TEST_WORKSPACE"

# Use correct Claude CLI syntax:
# -p/--print for non-interactive output
# --mcp-debug for MCP protocol logging (goes to stderr)
# Redirect stdout to output file, stderr to protocol log
if timeout 120 claude -p --mcp-debug "$(cat "$TEST_WORKSPACE/debug_prompt.txt")" \
    > "$claude_output_file" \
    2> "$claude_protocol_log"; then
    log_success "Claude execution completed"
else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        log_error "Claude execution timed out after 120 seconds"
    else
        log_error "Claude execution failed with exit code: $exit_code"
    fi
    log_info "Check protocol log: $claude_protocol_log"
    return 1
fi

cd "$PROJECT_ROOT"

# Step 8: Validate results
log_step "Step 8: Validating test results"

if [[ ! -f "$claude_output_file" ]]; then
    log_error "Claude output file not found"
    exit 1
fi

output_lines="$(wc -l < "$claude_output_file")"
if [[ $output_lines -eq 0 ]]; then
    log_error "Claude output is empty"
    exit 1
fi

log_success "Claude generated output ($output_lines lines)"

# Check if Claude identified the bug
if grep -qi "bug\|error\|wrong\|incorrect\|problem" "$claude_output_file"; then
    log_success "Claude identified there is a bug"
else
    log_error "Claude did not identify a bug"
    exit 1
fi

# Check if Claude found the location (line 21 or % 4)
if grep -Ei "line.*21|21.*line|% 4|modulo 4|mod 4" "$claude_output_file"; then
    log_success "Claude identified the bug location (line 21 or % 4)"
else
    log_error "Claude did not identify the specific bug location"
    exit 1
fi

# Check if debugger tools were used (optional)
if grep -qi "debugger.*start\|set.*breakpoint\|evaluate" "$claude_output_file"; then
    log_success "Claude used debugger tools"
else
    log_info "Claude did not use debugger tools (may have analyzed manually)"
fi

# Step 9: Display MCP protocol communication
log_step "Step 9: MCP Protocol Communication Summary"

if [[ -f "$claude_protocol_log" && -s "$claude_protocol_log" ]]; then
    protocol_lines="$(wc -l < "$claude_protocol_log")"
    log_info "Protocol log captured: $protocol_lines lines"
    log_info "Sample of MCP communication:"
    echo ""
    head -20 "$claude_protocol_log" || true
    echo ""
else
    log_info "No protocol log file generated"
fi

# Step 10: Final validation
log_step "Step 10: Final Test Validation"
echo ""
echo "================================================"
echo "Test Results Summary"
echo "================================================"

printf "Bug identified:        "
if grep -qi "bug\|error\|wrong" "$claude_output_file"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

printf "Location identified:   "
if grep -Ei "line.*21|% 4" "$claude_output_file"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

printf "Debugger tools used:   "
if grep -qi "debugger.*start\|breakpoint" "$claude_output_file"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}○${NC} (optional)"
fi

echo ""
log_success "Integration test PASSED"
echo ""
log_info "Output file: $claude_output_file"
log_info "Protocol log: $claude_protocol_log"
echo ""
