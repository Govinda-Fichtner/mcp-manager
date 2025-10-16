# Testing Guidelines for MCP Manager

## Testing Philosophy

- **Test behavior, not implementation**: Focus on what functions do, not how
- **Fast feedback**: Unit tests run in milliseconds, integration tests in seconds
- **CI-friendly**: Tests pass without Docker daemon or real credentials
- **Incremental**: Add tests with each new feature, never reduce coverage

## Test Organization

### Unit Tests (`spec/unit/`)

Test individual functions in isolation using mocks:

- **No external dependencies**: No Docker, no network, no filesystem (except test fixtures)
- **Mock everything**: Docker commands, yq parsing, file operations
- **Fast execution**: Entire suite runs in < 5 seconds
- **High coverage**: Aim for 80%+ line coverage of mcp_manager.sh

### Integration Testing Strategy

**Use `mcp_manager.sh health` command** to validate servers:

- Run `./mcp_manager.sh health <server>` after adding each server
- Validates image setup, container start, and MCP protocol compliance
- Manual validation during development, not automated CI tests
- For now, skip comprehensive `spec/integration/` tests in favor of health command

## Test Structure (ShellSpec)

### Basic Template

```bash
Describe 'Feature Name'
  Include spec/spec_helper.sh

  setup() {
    setup_test_env
    mock_docker
  }

  cleanup() {
    cleanup_test_env
  }

  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'function_name()'
    It 'describes expected behavior'
      When call function_name "arg1" "arg2"
      The status should equal 0
      The output should include "expected text"
    End
  End
End
```

### Assertions

```bash
# Exit code
The status should equal 0
The status should not equal 0

# Output (stdout)
The output should include "text"
The output should not include "text"

# Error output (stderr)
The stderr should include "error"

# File existence
The path "/tmp/file" should be file
The path "/tmp/dir" should be directory
```

## Mocking Patterns

### Mock Docker Commands

```bash
mock_docker() {
  docker() {
    case "$1" in
      "images")
        echo "REPOSITORY TAG IMAGE_ID"
        echo "test/image latest abc123"
        ;;
      "run")
        echo "container-id-12345"
        ;;
      "pull")
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  }
  export -f docker
}
```

### Mock yq Parsing

```bash
mock_yq() {
  yq() {
    case "$2" in
      '.servers["test-server"].name')
        echo "Test Server"
        ;;
      *)
        echo "null"
        ;;
    esac
  }
  export -f yq
}
```

## Testing New Servers

When adding a new MCP server, create tests for:

### 1. Registry Parsing

```bash
It 'parses server name from registry'
  When call parse_server_config "new-server" "name"
  The output should equal "New Server Name"
End

It 'parses server type from registry'
  When call get_server_type "new-server"
  The output should equal "api_based"
End

It 'parses environment variables from registry'
  When call parse_server_config "new-server" "environment_variables"
  The output should include "API_KEY"
End
```

### 2. Setup Logic

```bash
It 'pulls registry image for new server'
  When call setup_mcp_server "new-server"
  The status should equal 0
  The stderr should include "Pulling image"
End

It 'builds from repository for new server'
  When call setup_mcp_server "new-server"
  The status should equal 0
  The stderr should include "Building image"
End
```

### 3. Health Check

```bash
It 'passes health check with valid configuration'
  When call cmd_health "new-server"
  The status should equal 0
  The output should include "READY"
End

It 'fails health check with missing credentials'
  When call cmd_health "new-server"
  The status should equal 1
  The stderr should include "credentials"
End
```

## Manual Validation Workflow

After implementing a new server, validate with:

```bash
# 1. Setup the server (pull/build image)
./mcp_manager.sh setup <server-name>

# 2. Run health check
./mcp_manager.sh health <server-name>

# Expected output:
# ✓ Docker image exists
# ✓ Container starts successfully
# ✓ MCP protocol handshake succeeds
# ✓ Tools/resources discovered
# → Server READY
```

If health check passes, the server implementation is validated.

## Test-Driven Development Workflow

### Red-Green-Refactor

1. **Red**: Write failing test
   ```bash
   It 'supports new server type: privileged'
     When call get_server_type "docker"
     The output should equal "privileged"
   End
   # Run: npm test (FAILS)
   ```

2. **Green**: Implement minimum code to pass
   ```bash
   # Add to mcp_server_registry.yml
   docker:
     server_type: "privileged"
   # Run: npm test (PASSES)
   ```

3. **Refactor**: Improve code while keeping tests green
   ```bash
   # Extract common logic, rename variables, etc.
   # Run: npm test (STILL PASSES)
   ```

## Running Tests

```bash
# All tests
npm test

# Specific test file
npx shellspec spec/unit/health_command_spec.sh

# With coverage
npx shellspec --kcov

# Watch mode
npx shellspec --watch
```

## Test Fixtures

Store test data in `spec/fixtures/`:

- `sample_registry.yml`: Minimal test registry
- `mock_responses/`: Sample API responses for mocking
- `test_dockerfiles/`: Minimal Dockerfiles for testing builds

## Common Pitfalls

1. **Don't test external services**: Mock API calls, don't make real requests
2. **Don't hardcode paths**: Use `$TMP_DIR` from spec_helper.sh
3. **Don't assume Docker**: Check with `command -v docker` and skip if missing
4. **Don't leak state**: Always clean up in AfterEach hooks
5. **Don't test implementation details**: Test public function behavior only

## Coverage Goals

- **Unit tests**: 80%+ line coverage of mcp_manager.sh
- **Integration tests**: Cover all commands (setup, health, config, list)
- **Edge cases**: Test error conditions, missing files, invalid configs
- **Regression**: Add test for every bug fix to prevent recurrence
