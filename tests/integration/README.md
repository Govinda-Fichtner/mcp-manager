# Integration Tests

This directory contains integration tests that validate MCP servers work correctly with Claude Code.

## Available Tests

### test_debugger_python_fizzbuzz_claude.sh

Integration test validating the debugger-python server works with Claude Code (Python debugging).

### test_debugger_ruby_fizzbuzz_claude.sh

Integration test validating the debugger-ruby server works with Claude Code (Ruby debugging).

## Test Flow (both tests)

1. Validates Claude CLI is available and working
2. Checks appropriate debugger-mcp image exists (Python or Ruby)
3. Creates FizzBuzz implementation with intentional bug (line 21: `% 4` instead of `% 5`)
4. Generates MCP server configuration
5. Adds debugger server to Claude Code
6. Runs Claude Code to analyze and debug the FizzBuzz bug
7. Validates Claude identified the bug and its location
8. Captures MCP protocol communication (if debugger tools are used)
9. Automatically cleans up: removes MCP server and test workspace

## Prerequisites

- Claude Code CLI (`claude`) installed and in PATH
- Docker with appropriate debugger image built:
  - For Python test: `./mcp_manager.sh setup debugger-python`
  - For Ruby test: `./mcp_manager.sh setup debugger-ruby`
- `.env` file configured with `DEBUGGER_WORKSPACE`

## Running Tests

```bash
# Python debugger test
./tests/integration/test_debugger_python_fizzbuzz_claude.sh

# Ruby debugger test
./tests/integration/test_debugger_ruby_fizzbuzz_claude.sh

# Run both
for test in ./tests/integration/test_debugger_*.sh; do
    echo "Running $test..."
    bash "$test"
    echo ""
done
```

## Success Criteria

- ✅ Claude CLI available and functional
- ✅ Appropriate debugger image exists (debugger-mcp-python or debugger-mcp-ruby)
- ✅ Claude identifies there is a bug
- ✅ Claude identifies the bug location (line 21 or `% 4`)
- ○ Claude uses debugger MCP tools (optional - may analyze manually)

## Test Differences

| Aspect | Python Test | Ruby Test |
|--------|------------|-----------|
| Test file | `fizzbuzz.py` | `fizzbuzz.rb` |
| Language | Python 3 | Ruby |
| MCP Server | `debugger-python` | `debugger-ruby` |
| Docker Image | `local/debugger-mcp-python:latest` | `local/debugger-mcp-ruby:latest` |
| Workspace | `workspace_python/` | `workspace_ruby/` |
| MCP Server Name | `debugger-python-test` | `debugger-ruby-test` |

## Test Artifacts

All artifacts are created in temporary workspaces and automatically cleaned up on exit:
- `workspace_python/` - Python test artifacts
- `workspace_ruby/` - Ruby test artifacts

Each workspace contains:
- `fizzbuzz.{py,rb}` - FizzBuzz implementation with bug
- `debug_prompt.txt` - Prompt sent to Claude
- `claude_output.txt` - Claude's analysis results
- `mcp_protocol.log` - MCP protocol communication log

## Timeout

Claude execution has 120-second timeout. If test hangs, it will automatically abort and clean up.

## Running All Integration Tests

```bash
# From project root
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
