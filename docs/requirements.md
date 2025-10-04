# MCP Manager - MVP Requirements Document

**Version:** 1.0
**Date:** 2025-10-04
**Status:** Draft

---

## 1. Executive Summary

MCP Manager is a shell-based tool for managing Model Context Protocol (MCP) servers through Docker containerization. The MVP focuses on streamlined server deployment, configuration generation, and container lifecycle management with a Test-Driven Development approach.

---

## 2. Functional Requirements

### 2.1 Server Management

#### FR-SM-001: Add MCP Server
**Description:** Users shall be able to add an MCP server to the managed environment.

**Acceptance Criteria:**
- [ ] Command: `mcp-manager add <server-name>`
- [ ] Automatically detects source from `mcp_server_registry.yml`
- [ ] Supports GitHub repository URLs
- [ ] Supports local path for custom Dockerfiles
- [ ] Prompts for required environment variables
- [ ] Creates server entry in state file (`~/.mcp-manager/state.json`)
- [ ] Returns success/failure status with descriptive messages

**Example:**
```bash
$ mcp-manager add github
Adding GitHub MCP server...
Enter GitHub Personal Access Token: ****
Successfully added github server
```

**Test Cases:**
- Add server with valid GitHub URL
- Add server with custom Dockerfile
- Add server with missing environment variables
- Add duplicate server (should fail gracefully)

---

#### FR-SM-002: Remove MCP Server
**Description:** Users shall be able to remove a managed MCP server.

**Acceptance Criteria:**
- [ ] Command: `mcp-manager remove <server-name>`
- [ ] Stops running container if active
- [ ] Removes container and image
- [ ] Removes server from state file
- [ ] Prompts for confirmation before removal
- [ ] Option to skip confirmation with `--force` flag

**Example:**
```bash
$ mcp-manager remove github
Warning: This will stop and remove the github server. Continue? (y/N): y
Stopping container...
Removing container...
Removing image...
Successfully removed github server
```

**Test Cases:**
- Remove running server
- Remove stopped server
- Remove non-existent server (should fail gracefully)
- Force remove without confirmation

---

#### FR-SM-003: Build from Source
**Description:** Users shall be able to build MCP servers from source repositories.

**Acceptance Criteria:**
- [ ] Clone repository to temporary directory
- [ ] Detect Dockerfile location (root or `.docker/`)
- [ ] Build Docker image with appropriate tags
- [ ] Support multi-platform builds (amd64/arm64)
- [ ] Clean up temporary files after build
- [ ] Cache layers for faster rebuilds

**Example:**
```bash
$ mcp-manager build github
Cloning repository...
Building Docker image for linux/arm64...
Successfully built github:latest
```

**Test Cases:**
- Build from GitHub repository
- Build with custom Dockerfile path
- Build fails due to missing dependencies
- Build on amd64 vs arm64 platforms

---

#### FR-SM-004: Pull from Registry
**Description:** Users shall be able to pull pre-built MCP server images from container registries.

**Acceptance Criteria:**
- [ ] Support Docker Hub (`docker.io`)
- [ ] Support GitHub Container Registry (`ghcr.io`)
- [ ] Configuration via `mcp_server_registry.yml`
- [ ] Automatic platform detection
- [ ] Version pinning support (default: `latest`)
- [ ] Registry authentication support

**Example:**
```yaml
# mcp_server_registry.yml
github:
  registry: ghcr.io/modelcontextprotocol/server-github
  version: latest
  build_from_source: false
```

**Test Cases:**
- Pull from Docker Hub
- Pull from GitHub Container Registry
- Pull with version pinning
- Pull with authentication required
- Pull fails due to network issues

---

#### FR-SM-005: Version Management (Simplified)
**Description:** Users shall be able to specify MCP server versions via image tags.

**Acceptance Criteria:**
- [ ] Default to `latest` tag
- [ ] Support explicit version pinning in registry config
- [ ] **No rollback feature** (stateless design like MacbookSetup)
- [ ] Users manually remove and re-pull for version changes
- [ ] Preserve environment variables during re-setup

**Example:**
```bash
# Upgrade to latest (remove and re-pull)
$ mcp-manager remove github
$ mcp-manager setup github

# Or change registry to specific version
# registry.yml: image: ghcr.io/github/github-mcp-server:v1.2.3
$ mcp-manager setup github --force
```

**Test Cases:**
- Pull latest version
- Pin specific version in registry config
- Remove old version and pull new one
- **NO rollback** (stateless design)

---

### 2.2 Configuration Generation

#### FR-CG-001: Generate Server Config Snippet (Jinja2-based)
**Description:** Users shall be able to generate configuration snippets using Jinja2 templates.

**Acceptance Criteria:**
- [ ] Command: `mcp-manager config <server-name> --format <format>`
- [ ] Supported formats: `claude-code`, `claude-desktop`, `gemini-cli`
- [ ] **Use Jinja2 templates** from day 1 (not simple variable substitution)
- [ ] Output valid JSON/YAML for target platform
- [ ] Include environment variables from .env file
- [ ] Include volume mounts and network settings
- [ ] Option to output to file or stdout

**Implementation:**
- Uses `jinja2-cli` for template rendering
- Templates in `support/templates/` directory
- Build JSON context from registry, pass to Jinja2
- Per-server templates (like MacbookSetup)

**Example:**
```bash
$ mcp-manager config github --format claude-code
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "--env-file", "/path/.env", "github:latest"]
    }
  }
}
```

**Test Cases:**
- Generate Claude-Code config via Jinja2
- Generate Claude Desktop config via Jinja2
- Generate Gemini-CLI config via Jinja2
- Template includes work correctly
- Volume mounts rendered properly

---

#### FR-CG-002: Generate Complete Config File
**Description:** Users shall be able to generate complete configuration files containing all managed servers.

**Acceptance Criteria:**
- [ ] Command: `mcp-manager config --all --format <format>`
- [ ] Merge all server configs into single file
- [ ] Validate JSON/YAML syntax
- [ ] Backup existing config before overwriting
- [ ] Option to merge with existing config (Phase 2)

**Example:**
```bash
$ mcp-manager config --all --format claude-desktop --output ~/.config/claude/claude_desktop_config.json
Backing up existing config to claude_desktop_config.json.bak
Generated config for 2 servers
Config written to ~/.config/claude/claude_desktop_config.json
```

**Test Cases:**
- Generate config for all servers
- Output to stdout
- Output to file
- Backup existing config

---

### 2.3 Container Operations

#### FR-CO-001: Build with Custom Dockerfiles
**Description:** Users shall be able to provide custom Dockerfiles for MCP servers.

**Acceptance Criteria:**
- [ ] Support `dockerfile` field in registry config
- [ ] Support local file paths
- [ ] Support inline Dockerfile content
- [ ] Validate Dockerfile syntax before build
- [ ] Pass build arguments for environment variables

**Example:**
```yaml
# mcp_server_registry.yml
custom-server:
  dockerfile: ./dockerfiles/custom-server.Dockerfile
  env:
    - API_KEY
```

**Test Cases:**
- Build with local Dockerfile
- Build with inline Dockerfile
- Build fails due to syntax errors
- Build with build arguments

---

#### FR-CO-002: Pull from Container Registries
**Description:** Users shall be able to pull images from public and private container registries.

**Acceptance Criteria:**
- [ ] Auto-detect registry from image name
- [ ] Support authentication via Docker config
- [ ] Support platform-specific images
- [ ] Retry logic for network failures
- [ ] Progress indication for large images

**Test Cases:**
- Pull from Docker Hub
- Pull from private registry with auth
- Pull fails due to missing image
- Pull multi-platform image

---

#### FR-CO-003: Volume Mounting
**Description:** Users shall be able to configure persistent volumes for MCP servers.

**Acceptance Criteria:**
- [ ] Support named volumes
- [ ] Support bind mounts
- [ ] Configure via `volumes` field in registry
- [ ] Auto-create directories for bind mounts
- [ ] Read-only mount support

**Example:**
```yaml
obsidian:
  volumes:
    - ${HOME}/Documents/ObsidianVault:/vault:ro
```

**Test Cases:**
- Mount named volume
- Mount bind mount
- Mount read-only volume
- Mount non-existent directory (should create)

---

#### FR-CO-004: Host Network Access
**Description:** MCP servers shall have network access for API calls.

**Acceptance Criteria:**
- [ ] Default to `--network host` for simplicity
- [ ] Support custom networks (Phase 2)
- [ ] Validate network connectivity during health checks
- [ ] Document security implications

**Test Cases:**
- Container can reach external APIs
- Container respects network timeouts
- Network failures are logged

---

#### FR-CO-005: Environment Variable Injection
**Description:** Users shall be able to inject environment variables into containers from a global `.env` file.

**Acceptance Criteria:**
- [ ] Load variables from `~/.mcp-manager/.env`
- [ ] Support per-server environment variables
- [ ] Variable interpolation from global env
- [ ] Validation of required variables before container start
- [ ] Secrets are never logged or displayed

**Example:**
```bash
# ~/.mcp-manager/.env
GITHUB_PAT=ghp_xxxxxxxxxxxx
OBSIDIAN_VAULT_PATH=/home/user/vault
```

**Test Cases:**
- Load global .env file
- Override with server-specific env
- Missing required variable (should fail)
- Variable interpolation

---

### 2.4 State Management (Stateless Design)

#### FR-ST-001: Server Information (Query Docker)
**Description:** Users shall be able to query information about servers via Docker commands.

**Acceptance Criteria:**
- [ ] Command: `mcp-manager info <server-name>`
- [ ] Query Docker directly (no state file)
- [ ] Display image information from `docker images`
- [ ] Display container status from `docker ps`
- [ ] Display configuration from registry (redact secrets)
- [ ] Display volume mounts from registry
- [ ] **No persistent state file** (stateless like MacbookSetup)

**Example:**
```bash
$ mcp-manager info github
Server: github
Registry Image: ghcr.io/github/github-mcp-server:latest
Local Image: ghcr.io/github/github-mcp-server:latest
Image Status: present (pulled 2 hours ago)
Container Status: not running
Environment Variables: GITHUB_PERSONAL_ACCESS_TOKEN (set)
Volumes: None
```

**Test Cases:**
- Info for image present but not running
- Info for non-existent image
- Secrets are properly redacted
- Registry info displayed correctly

---

#### FR-ST-002: Health Checks (Docker-based)
**Description:** Users shall be able to check server health via Docker status.

**Acceptance Criteria:**
- [ ] Command: `mcp-manager health <server-name>`
- [ ] Check if Docker image exists (`docker images`)
- [ ] Basic Docker connectivity check
- [ ] **No MCP protocol testing** in MVP (deferred to Phase 2)
- [ ] Return exit code 0 for healthy, non-zero for unhealthy

**Example:**
```bash
$ mcp-manager health github
Checking github server health...
✓ Docker image present
✓ Docker daemon accessible
Status: READY
```

**Test Cases:**
- Health check for existing image
- Health check for missing image
- Health check when Docker not running

---

#### FR-ST-003: No Container State Tracking (Stateless)
**Description:** The system shall NOT maintain persistent state files.

**Rationale:**
- **MacbookSetup proven pattern**: No state file = no corruption issues
- **Query Docker directly**: Always accurate, never stale
- **Simpler implementation**: Fewer edge cases, less code
- **No rollback needed**: Users remove and rebuild if version change needed

**Implementation:**
- No `~/.mcp-manager/state.json` file
- Optional minimal `mcp.json` (just last setup timestamp)
- All queries via `docker images`, `docker ps`, `docker inspect`

**Test Cases:**
- No state file created after operations
- Info command works without state file
- Multiple invocations don't create state pollution

---

### 2.5 Dependency Management

#### FR-DM-001: Dependency Checking
**Description:** The tool shall verify required dependencies are installed.

**Acceptance Criteria:**
- [ ] Check for Docker (docker command available)
- [ ] Check for yq (YAML processor)
- [ ] Check for git (for source builds - Phase 1)
- [ ] Check for jq (JSON processor)
- [ ] **Check for jinja2-cli** (template rendering - Phase 1)
- [ ] Display clear error messages for missing deps
- [ ] Provide installation instructions per platform

**Required Dependencies (Phase 1):**
- `docker` - Container runtime
- `yq` (v4+) - YAML parsing
- `jq` - JSON processing
- `git` - Repository cloning for build from source
- `jinja2-cli` - Template rendering (Python package)

**Example:**
```bash
$ mcp-manager setup github
Error: jinja2-cli is not installed
Please install: pip install jinja2-cli
Or: brew install jinja2-cli (macOS)
```

**Test Cases:**
- All dependencies present
- Missing Docker
- Missing yq
- Missing git
- Missing jq
- Missing jinja2-cli

---

#### FR-DM-002: Clear Error Messages
**Description:** All error conditions shall provide actionable guidance to users.

**Acceptance Criteria:**
- [ ] Error messages include context (what failed, why)
- [ ] Suggest corrective actions
- [ ] Link to documentation where appropriate
- [ ] Use consistent error format
- [ ] Exit with appropriate error codes

**Example Error Codes:**
- 0: Success
- 1: General error
- 2: Missing dependency
- 3: Invalid configuration
- 4: Container operation failed
- 5: Network error

**Test Cases:**
- Missing dependency error
- Invalid config error
- Container start failure
- Network timeout

---

## 3. Non-Functional Requirements

### 3.1 Test-Driven Development

#### NFR-TDD-001: Shellspec Test Coverage
**Description:** All functionality shall be verified through automated tests.

**Acceptance Criteria:**
- [ ] Minimum 80% code coverage
- [ ] Unit tests for all functions
- [ ] Integration tests for end-to-end workflows
- [ ] Fast unit tests (<5s total runtime)
- [ ] Integration tests may be slower but still reasonable (<30s)
- [ ] Tests run in CI/CD pipeline

**Test Categories:**
- **Unit Tests:** Isolated function testing with mocked dependencies
- **Integration Tests:** Real Docker builds, container operations
- **Smoke Tests:** Quick verification of core functionality

---

### 3.2 Platform Support

#### NFR-PS-001: Platform Detection
**Description:** The tool shall automatically detect and adapt to the host platform.

**Acceptance Criteria:**
- [ ] Detect amd64/x86_64 architecture
- [ ] Detect arm64/aarch64 architecture
- [ ] Pull platform-appropriate images
- [ ] Build images for target platform
- [ ] Fail gracefully on unsupported platforms

**Test Cases:**
- Run on amd64 Linux
- Run on arm64 Linux
- Run on macOS (amd64/arm64)
- Run on unsupported platform

---

### 3.3 Performance

#### NFR-PERF-001: Fast Unit Tests
**Description:** Unit tests shall execute quickly to enable rapid development.

**Acceptance Criteria:**
- [ ] Unit test suite completes in <5 seconds
- [ ] Use mocking for Docker/network operations
- [ ] No actual containers created in unit tests
- [ ] Tests can run offline

---

#### NFR-PERF-002: Reasonable Integration Tests
**Description:** Integration tests shall verify real-world behavior efficiently.

**Acceptance Criteria:**
- [ ] Integration test suite completes in <30 seconds
- [ ] Use small test containers
- [ ] Clean up resources after tests
- [ ] Tests can be run selectively

---

### 3.4 Modularity

#### NFR-MOD-001: Modular Design
**Description:** The codebase shall be organized for easy extension and maintenance.

**Acceptance Criteria:**
- [ ] Separate modules for: server management, config generation, container ops, state management
- [ ] Functions are single-purpose (<50 lines)
- [ ] Clear interfaces between modules
- [ ] New servers can be added via config only
- [ ] Minimal code changes for new features

**Module Structure:**
```
lib/
├── server_manager.sh    # Server add/remove/list
├── config_generator.sh  # Config file generation
├── container_ops.sh     # Docker operations
├── state_manager.sh     # State persistence
├── dependency_checker.sh # Dependency validation
└── utils.sh             # Common utilities
```

---

## 4. MVP Scope & Phasing

### Phase 1: Core MVP (Current)
**Target Date:** Week 1-2

**In Scope:**
- **GitHub MCP server support**
- **Registry pull support** (FR-SM-004: Pull from Docker Hub, GHCR)
- **Build from source** (FR-SM-003: Clone repo, build Docker image)
- **Jinja2 config generation** (Claude-Code format) from day 1
- **Container lifecycle** (add, remove, info, health)
- **No state management file** (stateless design like MacbookSetup)
- **Dependency checking** (docker, yq, jinja2-cli)
- **Shellspec test framework** (unit tests, integration deferred)

**Success Criteria:**
- Can pull GitHub MCP server from registry
- Can build Obsidian MCP server from source
- Can generate working Claude-Code config using Jinja2
- Can verify server health (basic Docker checks)
- 80%+ unit test coverage (fast, no Docker)

**Key Changes from Original Proposal:**
- ✅ **Both registry pull AND build from source** in Phase 1 (not split)
- ✅ **Jinja2 templates** from day 1 (not simple variable substitution)
- ✅ **Stateless design** (no .mcp-manager-state.json file)
- ✅ **Unit tests only** for MVP (integration tests deferred)

---

### Phase 2: Expansion
**Target Date:** Week 2-3

**In Scope:**
- **Obsidian MCP server support** (with volume mounts)
- **Additional config formats** (Claude Desktop, Gemini-CLI via Jinja2)
- **Config snippet generation** (merge-ready fragments)
- **Enhanced health checks** (MCP protocol validation)
- **Volume mount configuration** (filesystem, vault access)
- **Enhanced error handling** (better diagnostics)

**Success Criteria:**
- Supports 2+ MCP servers (GitHub + Obsidian)
- Multiple config format options (3+ clients)
- Volume mounts working for Obsidian vault access

---

### Phase 3: Polish (Future)
**Deferred to Post-MVP:**

- Credential encryption
- Multi-server orchestration
- GUI/TUI interface
- Advanced rollback mechanisms
- Custom network configurations
- Plugin system for new servers
- Cloud deployment options

---

## 5. Out of Scope

The following features are explicitly **not** part of the MVP and will be considered for future releases:

1. **Security/Encryption**
   - Encrypted credential storage
   - Secret rotation
   - Vault integration

2. **Advanced Features**
   - Multi-server dependencies
   - Server orchestration workflows
   - Auto-scaling
   - High availability

3. **User Interfaces**
   - Web-based GUI
   - TUI/ncurses interface
   - IDE plugins

4. **Advanced Operations**
   - Blue-green deployments
   - Canary releases
   - Automated rollbacks
   - Performance monitoring

---

## 6. Acceptance Criteria Summary

### Definition of Done (MVP)
A feature is considered complete when:

1. ✅ **Implemented:** Code written and follows shell best practices
2. ✅ **Tested:** Unit and integration tests passing (80%+ coverage)
3. ✅ **Documented:** Usage documented in README or help text
4. ✅ **Reviewed:** Code reviewed for quality and security
5. ✅ **Verified:** Manually tested on target platforms

### MVP Completion Criteria
The MVP is considered complete when:

- [ ] GitHub MCP server can be added and managed
- [ ] Configuration can be generated for Claude-Code
- [ ] Containers can be built, started, stopped, removed
- [ ] State is persisted and queryable
- [ ] Health checks work reliably
- [ ] Dependencies are validated
- [ ] Test coverage ≥80%
- [ ] Documentation is complete
- [ ] All acceptance criteria for Phase 1 features are met

---

## 7. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Docker API changes | High | Low | Pin Docker version in requirements |
| Platform-specific bugs | Medium | Medium | Test on multiple platforms early |
| State file corruption | High | Low | Atomic writes, backup mechanism |
| Missing dependencies | Medium | High | Clear error messages, install docs |
| Container security issues | High | Low | Use official images, document risks |

---

## 8. Dependencies

### Required External Dependencies
- **Docker:** Container runtime (20.10+ recommended)
- **yq:** YAML processor (v4.0+ for consistent behavior)
- **jq:** JSON processor (1.6+)
- **git:** For source builds
- **bash:** Shell (4.0+ for associative arrays)

### Optional Dependencies
- **shellspec:** For running tests (development only)

---

## 9. References

- MCP Specification: [Model Context Protocol](https://modelcontextprotocol.io/)
- GitHub MCP Server: [modelcontextprotocol/server-github](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- Obsidian MCP Server: [modelcontextprotocol/server-obsidian](https://github.com/modelcontextprotocol/servers/tree/main/src/obsidian)
- Docker Documentation: [docs.docker.com](https://docs.docker.com/)
- Shellspec: [shellspec.info](https://shellspec.info/)

---

## 10. Appendix: Example Usage Scenarios

### Scenario 1: New User Setup
```bash
# Install dependencies
sudo apt-get install docker yq jq git

# Initialize MCP Manager
mcp-manager init

# Add GitHub server
mcp-manager add github
# Prompts for GITHUB_PAT

# Generate config
mcp-manager config github --format claude-code --output ~/.config/claude-code/mcp.json

# Verify health
mcp-manager health github
```

### Scenario 2: Adding Multiple Servers
```bash
# Add GitHub
mcp-manager add github

# Add Obsidian
mcp-manager add obsidian

# Generate combined config
mcp-manager config --all --format claude-desktop --output ~/.config/claude/claude_desktop_config.json

# Check status of all servers
mcp-manager list
```

### Scenario 3: Troubleshooting
```bash
# Check server info
mcp-manager info github

# Run health check
mcp-manager health github

# View logs
mcp-manager logs github --tail 50

# Restart server
mcp-manager restart github
```

---

**Document Status:** Ready for Review
**Next Steps:** Begin TDD implementation starting with dependency checking module
