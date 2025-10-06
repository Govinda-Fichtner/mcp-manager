# Integration Tests

This directory contains integration tests that validate MCP servers work correctly with Claude Code.

## Available Tests

### test_debugger_fizzbuzz_claude.sh

Integration test validating the debugger-mcp server works with Claude Code.

**Test Flow:**
1. Validates Claude CLI is available and working
2. Checks debugger-mcp Docker image exists
3. Creates FizzBuzz implementation with intentional bug (line 21: `% 4` instead of `% 5`)
4. Generates MCP server configuration
5. Adds debugger-mcp server to Claude Code
6. Runs Claude Code to analyze and debug the FizzBuzz bug
7. Validates Claude identified the bug and its location
8. Captures MCP protocol communication (if debugger tools are used)
9. Automatically cleans up: removes MCP server and test workspace

**Prerequisites:**
- Claude Code CLI (`claude`) installed and in PATH
- Docker with debugger-mcp image built
- `.env` file configured with `DEBUGGER_WORKSPACE`

**Run Test:**
```bash
./tests/integration/test_debugger_fizzbuzz_claude.sh
```

**Success Criteria:**
- ✅ Claude CLI available and functional
- ✅ debugger-mcp image exists
- ✅ Claude identifies there is a bug
- ✅ Claude identifies the bug location (line 21 or `% 4`)
- ○ Claude uses debugger MCP tools (optional - may analyze manually)

**Test Artifacts:**
All artifacts are created in temporary workspace and automatically cleaned up on exit.

**Timeout:**
Claude execution has 120-second timeout. If test hangs, it will automatically abort and clean up.

## Running All Integration Tests

```bash
# Run all tests
for test in tests/integration/test_*.sh; do
    echo "Running $test..."
    bash "$test"
    echo ""
done
```

## Adding New Integration Tests

1. Create new test script: `test_<server>_<scenario>.sh`
2. Follow the pattern from existing tests:
   - Use colored output helpers (log_step, log_success, log_error, log_info)
   - Implement cleanup trap to remove MCP server and artifacts
   - Validate prerequisites before running main test
   - Use timeouts for commands that may hang
   - Provide clear success/failure output
3. Document the test in this README
4. Add test to CI/CD pipeline (if applicable)

## Troubleshooting

**Claude CLI not found:**
- Install Claude Code from https://claude.com/claude-code
- Verify `claude --version` works

**Docker image not found:**
- Run `./mcp_manager.sh setup <server>` to build the image
- Verify with `docker images | grep <server>`

**Test hangs:**
- Tests have built-in timeouts
- Press Ctrl+C to trigger cleanup trap
- Check protocol log in workspace for debugging

**MCP server config left behind:**
- Run `claude mcp list` to see configured servers
- Remove manually with `claude mcp remove <server-name>`
