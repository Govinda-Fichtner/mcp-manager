# Claude Code Configuration for MCP Manager

## 🚨 CRITICAL: Git Commit Guidelines

### NEVER Add Attribution in Commits

**ABSOLUTE RULE**: When creating git commits or push messages:

1. ❌ **NEVER** add "Generated with Claude Code" attribution
2. ❌ **NEVER** add "Co-Authored-By: Claude" footer
3. ❌ **NEVER** add any Claude-related attribution or references
4. ✅ **ALWAYS** use clean, professional commit messages without AI attribution

**Author Configuration:**
- Author Name: `peter-ai-buddy`
- Author Email: `peter-ai-buddy@urknall.ai`
- Git config is already set - do not modify

### Commit Message Format

```
<type>: <short description>

- Bullet point describing change
- Another change
- More details as needed

Optional paragraph with context or rationale.
```

**Example Good Commit:**
```
feat: add health check timeout configuration

- Implement per-server configurable timeouts from registry
- Default timeout set to 5 seconds
- Add validation for timeout values
```

**Example Bad Commit (DO NOT DO THIS):**
```
feat: add health check timeout configuration

- Implement per-server configurable timeouts

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Architecture Principles

### Server Type Taxonomy

MCP servers are classified by their resource requirements and runtime behavior:

- **`api_based`**: Requires API tokens/credentials, network access only
- **`mount_based`**: Requires Docker volume mounts for data persistence
- **`standalone`**: No authentication, self-contained functionality
- **`privileged`**: Requires special permissions (docker.sock, host network)
- **`remote`**: Cloudflare Workers/SSE endpoints, no local Docker container

### Source Type System

Three ways to obtain MCP server images:

- **`registry`**: Pull from Docker registry (ghcr.io, Docker Hub)
- **`repository`**: Clone Git repo and build from Dockerfile
- **`dockerfile`**: Build from local Dockerfile in support/docker/

### Registry Schema Evolution

The `mcp_server_registry.yml` schema evolves as we add servers. Key principles:

- Server definitions are self-contained (all info in one place)
- Required fields: `name`, `server_type`, `source`, `category`
- Optional fields: `environment_variables`, `volumes`, `docker`, `health_test`
- Schema adapts to server needs (not vice versa)

### Health Check Strategy

Four-level health check system:

1. **Setup validation**: Docker image exists
2. **Basic functionality**: Container starts without errors
3. **Protocol compliance**: MCP initialize/initialized handshake
4. **Full functionality**: Server-specific API calls (optional)

Levels 1-3 are mandatory, level 4 is server-specific.

## Adding New MCP Servers

### TDD Workflow (Feature Branch per Server)

```bash
# 1. Create feature branch
git checkout -b feat/add-<server-name>

# 2. Add registry entry (schema first)
# Edit mcp_server_registry.yml

# 3. Write failing tests
# spec/unit/servers/<server>_spec.sh

# 4. Implement minimum code to pass tests
# Update mcp_manager.sh functions

# 5. Commit incrementally (small, atomic commits)
git add mcp_server_registry.yml spec/
git commit -m "test: add <server> registry entry and tests"

git add mcp_manager.sh
git commit -m "feat: implement <server> server support"

# 6. Verify all tests pass
npm test

# 7. Merge to main
git checkout main && git merge feat/add-<server-name>
```

### Extension Pattern

To add a new server:

1. **Registry entry**: Add to `mcp_server_registry.yml` with appropriate `server_type`
2. **Server-type logic**: Implement type-specific handling if not already covered
3. **Tests**: Add unit tests for new functionality
4. **Documentation**: Update README.md if user-facing changes

### Code Organization

- **mcp_manager.sh**: Main script, functions organized by concern
- **mcp_server_registry.yml**: Single source of truth for server configs
- **spec/unit/**: Unit tests with mocks (no Docker/API calls)
- **spec/integration/**: Integration tests (Docker + basic MCP protocol)
- **support/docker/**: Custom Dockerfiles for servers needing build
- **docs/**: User documentation and troubleshooting guides
- **spec/CLAUDE.md**: Testing-specific guidelines and patterns

## Development Workflow

### Daily Development

1. Create feature branch for focused change
2. Write tests first (TDD)
3. Implement minimum code to pass
4. Run tests: `npm test`
5. Commit small increments
6. Merge when feature complete

### Pre-commit Hooks

Automated checks run on commit:
- ShellCheck (linting)
- ShellSpec tests
- Whitespace/file checks

All must pass before commit succeeds.

## Code Style

- Follow existing bash conventions
- Use shellcheck directives for intentional violations
- Keep functions focused (single responsibility)
- Comment complex logic, not obvious code
- Prefer clarity over cleverness
