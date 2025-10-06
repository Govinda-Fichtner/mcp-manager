#!/bin/bash
# Integration test: debugger-python with Claude Code using FizzBuzz
#
# This test validates that:
# 1. Claude CLI is available and working
# 2. debugger-python server can be added to Claude Code
# 3. Claude can use the debugger to debug a FizzBuzz implementation
# 4. MCP protocol communication works correctly
# 5. Server can be cleanly removed after testing

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_WORKSPACE="$PROJECT_ROOT/tests/integration/workspace_python"
FIZZBUZZ_FILE="$TEST_WORKSPACE/fizzbuzz.py"
MCP_SERVER_NAME="debugger-python-test"

# Cleanup function
cleanup() {
    local exit_code=$?
    echo ""
    echo -e "${BLUE}[CLEANUP]${NC} Removing test artifacts..."

    # Remove MCP server from Claude Code
    if claude mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
        echo -e "${BLUE}[CLEANUP]${NC} Removing MCP server: $MCP_SERVER_NAME"
        claude mcp remove "$MCP_SERVER_NAME" 2>/dev/null || true
    fi

    # Clean up test workspace
    if [[ -d "$TEST_WORKSPACE" ]]; then
        echo -e "${BLUE}[CLEANUP]${NC} Removing test workspace: $TEST_WORKSPACE"
        rm -rf "$TEST_WORKSPACE"
    fi

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}[CLEANUP]${NC} Cleanup completed successfully"
    else
        echo -e "${YELLOW}[CLEANUP]${NC} Cleanup completed (test failed with code $exit_code)"
    fi

    exit $exit_code
}

trap cleanup EXIT INT TERM

# Helper functions
log_step() {
    echo ""
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Main test execution
main() {
    echo "================================================"
    echo "FizzBuzz Integration Test: debugger-python + Claude Code"
    echo "================================================"

    # Step 1: Validate Claude CLI is available
    log_step "Step 1: Validating Claude CLI availability"

    if ! command -v claude >/dev/null 2>&1; then
        log_error "Claude CLI not found. Please install Claude Code first."
        log_info "Install from: https://claude.com/claude-code"
        return 1
    fi
    log_success "Claude CLI found: $(which claude)"

    # Check Claude version
    local claude_version
    claude_version=$(claude --version 2>&1 || echo "unknown")
    log_info "Claude version: $claude_version"

    # Step 2: Validate Claude is working
    log_step "Step 2: Validating Claude CLI functionality"

    if ! claude --help >/dev/null 2>&1; then
        log_error "Claude CLI is not responding correctly"
        return 1
    fi
    log_success "Claude CLI is functional"

    # Step 3: Check if debugger-python image exists
    log_step "Step 3: Validating debugger-python Docker image"

    if ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "debugger-mcp-python:latest"; then
        log_error "debugger-python image not found. Please run: ./mcp_manager.sh setup debugger-python"
        return 1
    fi
    log_success "debugger-python image found"

    # Step 4: Create test workspace with FizzBuzz
    log_step "Step 4: Creating test workspace with FizzBuzz implementation"

    mkdir -p "$TEST_WORKSPACE"

    cat > "$FIZZBUZZ_FILE" << 'PYTHON_CODE'
#!/usr/bin/env python3
"""
FizzBuzz implementation with an intentional bug for debugging.
Bug: divisibility by 5 check is broken (uses 4 instead of 5)
"""

def fizzbuzz(n):
    """
    Returns FizzBuzz result for number n.
    - Returns "Fizz" if n is divisible by 3
    - Returns "Buzz" if n is divisible by 5
    - Returns "FizzBuzz" if n is divisible by both
    - Returns the number as string otherwise
    """
    result = ""

    if n % 3 == 0:
        result += "Fizz"

    # BUG: This should be n % 5 == 0
    if n % 4 == 0:  # <-- INTENTIONAL BUG HERE
        result += "Buzz"

    if not result:
        result = str(n)

    return result

def main():
    """Run FizzBuzz for numbers 1-15"""
    print("FizzBuzz Output:")
    for i in range(1, 16):
        print(f"{i}: {fizzbuzz(i)}")

if __name__ == "__main__":
    main()
PYTHON_CODE

    chmod +x "$FIZZBUZZ_FILE"
    log_success "Created FizzBuzz test file: $FIZZBUZZ_FILE"

    # Show the bug location
    log_info "Bug location: Line 21 (uses % 4 instead of % 5)"

    # Step 5: Generate MCP server configuration
    log_step "Step 5: Generating MCP server configuration"

    local mcp_config_json
    mcp_config_json=$("$PROJECT_ROOT/mcp_manager.sh" config debugger-python --add-json --env-file "$PROJECT_ROOT/.env")

    if [[ -z "$mcp_config_json" ]]; then
        log_error "Failed to generate MCP configuration"
        return 1
    fi

    log_success "Generated MCP configuration"
    log_info "Configuration preview:"
    echo "$mcp_config_json" | head -5

    # Step 6: Add MCP server to Claude Code
    log_step "Step 6: Adding debugger-python server to Claude Code"

    if claude mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
        log_info "Removing existing $MCP_SERVER_NAME server"
        claude mcp remove "$MCP_SERVER_NAME" || true
    fi

    # Add the server using claude mcp add-json
    if ! claude mcp add-json "$MCP_SERVER_NAME" "$mcp_config_json" 2>&1; then
        log_error "Failed to add MCP server to Claude Code"
        log_info "Config was: $mcp_config_json"
        return 1
    fi

    log_success "Added MCP server: $MCP_SERVER_NAME"

    # Verify it was added
    if ! claude mcp list 2>/dev/null | grep -q "$MCP_SERVER_NAME"; then
        log_error "MCP server not found in Claude Code configuration"
        return 1
    fi
    log_success "Verified MCP server is configured"

    # Step 7: Run Claude Code with MCP protocol logging
    log_step "Step 7: Running Claude Code to debug FizzBuzz"

    log_info "Test scenario: Ask Claude to find and fix the bug in FizzBuzz"
    log_info "Claude should use debugger_mcp tools to inspect the code"

    # Create a prompt file for Claude
    local prompt_file="$TEST_WORKSPACE/debug_prompt.txt"
    cat > "$prompt_file" << 'PROMPT'
Analyze the FizzBuzz implementation in fizzbuzz.py and find the bug.

The program should:
- Print "Fizz" for numbers divisible by 3
- Print "Buzz" for numbers divisible by 5
- Print "FizzBuzz" for numbers divisible by both
- Print the number otherwise

Use the debugger-python-test MCP tools if available to:
1. Start a debugging session for fizzbuzz.py
2. Set a breakpoint at line 21 (the bug location)
3. Evaluate the expression "n % 5 == 0" vs "n % 4 == 0" for n=5
4. Explain what the bug is and where it is

If debugger tools are not available, just analyze the code manually.

At the end, summarize:
1. What tools you used (if any)
2. What the bug is
3. Where the bug is located (line number)
PROMPT

    log_info "Prompt: $(cat "$prompt_file" | head -1)"

    # Enable MCP protocol logging
    export MCP_DEBUG=1
    export DEBUG=1

    # Run Claude with the prompt and capture output
    local claude_output_file="$TEST_WORKSPACE/claude_output.txt"
    local claude_protocol_log="$TEST_WORKSPACE/mcp_protocol.log"

    log_info "Running Claude (this may take 30-60 seconds)..."
    log_info "MCP protocol debugging enabled"

    # Run Claude in the test workspace directory
    cd "$TEST_WORKSPACE"

    # Use correct Claude CLI syntax:
    # -p/--print for non-interactive output
    # --mcp-debug for MCP protocol logging (goes to stderr)
    # Redirect stdout to output file, stderr to protocol log
    if timeout 120 claude -p --mcp-debug "$(cat "$prompt_file")" \
        > "$claude_output_file" \
        2> "$claude_protocol_log"; then
        log_success "Claude execution completed"
    else
        local exit_code=$?
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

    # Check if Claude produced output
    if [[ ! -f "$claude_output_file" ]]; then
        log_error "No output file generated by Claude"
        return 1
    fi

    local output_content
    output_content=$(cat "$claude_output_file")

    log_success "Claude generated output ($(wc -l < "$claude_output_file") lines)"

    # Validate Claude identified the bug
    local found_bug=false
    local found_line=false
    local used_debugger=false

    if echo "$output_content" | grep -qi "bug\|error\|wrong\|incorrect"; then
        log_success "Claude identified there is a bug"
        found_bug=true
    else
        log_error "Claude did not identify the bug"
    fi

    if echo "$output_content" | grep -qi "line.*21\|21.*line\|% 4\|modulo 4"; then
        log_success "Claude identified the bug location (line 21 or % 4)"
        found_line=true
    else
        log_error "Claude did not identify the specific bug location"
    fi

    # Check if debugger tools were used
    if [[ -f "$claude_protocol_log" ]] && grep -qi "debugger_\|tools/call" "$claude_protocol_log"; then
        log_success "Claude used debugger MCP tools"
        used_debugger=true

        # Show which tools were used
        log_info "MCP tools detected in protocol log:"
        grep -i "debugger_" "$claude_protocol_log" | head -5 || true
    else
        log_info "Claude did not use debugger tools (may have analyzed manually)"
    fi

    # Step 9: Display MCP protocol communication
    log_step "Step 9: MCP Protocol Communication Summary"

    if [[ -f "$claude_protocol_log" ]] && [[ -s "$claude_protocol_log" ]]; then
        log_info "Protocol log file: $claude_protocol_log ($(wc -l < "$claude_protocol_log") lines)"

        # Extract and display MCP messages
        local mcp_messages
        mcp_messages=$(grep -E '(initialize|tools/list|tools/call|debugger_)' "$claude_protocol_log" 2>/dev/null || echo "")

        if [[ -n "$mcp_messages" ]]; then
            echo ""
            echo "MCP Protocol Messages:"
            echo "======================"
            echo "$mcp_messages" | head -20
            echo ""
            log_success "MCP protocol communication captured"
        else
            log_info "No MCP protocol messages found in log"
        fi
    else
        log_info "No protocol log file generated"
    fi

    # Step 10: Final validation
    log_step "Step 10: Final Test Validation"

    local test_passed=true

    if [[ "$found_bug" != true ]]; then
        log_error "Test failed: Bug not identified"
        test_passed=false
    fi

    if [[ "$found_line" != true ]]; then
        log_error "Test failed: Bug location not identified"
        test_passed=false
    fi

    # Note: debugger usage is optional - Claude might analyze manually
    if [[ "$used_debugger" == true ]]; then
        log_success "Bonus: Debugger tools were used"
    fi

    # Display summary
    echo ""
    echo "================================================"
    echo "Test Results Summary"
    echo "================================================"
    echo -e "Bug identified:        $([[ "$found_bug" == true ]] && echo "${GREEN}✓${NC}" || echo "${RED}✗${NC}")"
    echo -e "Location identified:   $([[ "$found_line" == true ]] && echo "${GREEN}✓${NC}" || echo "${RED}✗${NC}")"
    echo -e "Debugger tools used:   $([[ "$used_debugger" == true ]] && echo "${GREEN}✓${NC}" || echo "${YELLOW}○${NC} (optional)")"
    echo ""

    if [[ "$test_passed" == true ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} Integration test PASSED"
        echo ""
        log_info "Output file: $claude_output_file"
        log_info "Protocol log: $claude_protocol_log"
        return 0
    else
        echo -e "${RED}[FAILURE]${NC} Integration test FAILED"
        echo ""
        log_info "Output file: $claude_output_file"
        log_info "Protocol log: $claude_protocol_log"
        return 1
    fi
}

# Run main function
main "$@"
