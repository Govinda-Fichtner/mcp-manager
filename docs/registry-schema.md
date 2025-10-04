# MCP Server Registry Schema - MVP

## Executive Summary

This document defines the optimized registry schema for the MCP Manager MVP, focusing on **GitHub** and **Obsidian** servers. The schema has been simplified from the existing MacbookSetup registry while maintaining compatibility and extensibility.

## MVP Schema (YAML Format)

```yaml
# Global configuration
global:
  build_directory: "./mcp_builds"       # Where to clone/build repositories
  network_name: "mcp-network"           # Default Docker network name
  default_timeout: 30                   # Default health check timeout (seconds)

# Server definitions
servers:
  <server-name>:
    # REQUIRED FIELDS
    name: string                        # Human-readable server name
    description: string                 # What this server does
    category: string                    # Server category (code, knowledge, etc.)

    # SOURCE CONFIGURATION (REQUIRED)
    source:
      type: enum                        # "registry" or "build"

      # For type: registry
      image: string                     # Pre-built image name (e.g., "mcp/github:latest")

      # For type: build
      repository: string                # Git repository URL
      build_context: string             # Build context directory (default: ".")
      dockerfile: string                # Path to Dockerfile (optional)
      image: string                     # Local tag name (e.g., "local/obsidian-mcp:latest")

    # ENVIRONMENT & RUNTIME (OPTIONAL)
    environment_variables:              # List of required environment variables
      - string                          # Variable name (e.g., "GITHUB_TOKEN")

    volumes:                            # Volume mounts (optional)
      - string                          # Format: "ENV_VAR:/container/path" or "/host/path:/container/path"

    # HEALTH CHECK (OPTIONAL)
    health_test:
      type: enum                        # "stdio_jsonrpc" or "json" (default: none)
      method: string                    # For stdio_jsonrpc: method name
      params: object                    # For stdio_jsonrpc: parameters
      expected_response: object         # Expected response structure

    startup_timeout: number             # Override default timeout for slow servers (optional)
```

## Field Reference Table

| Field | Required | Type | Default | Purpose | Example |
|-------|----------|------|---------|---------|---------|
| **Server Identification** |
| `name` | Yes | string | - | Human-readable server name | "GitHub MCP Server" |
| `description` | Yes | string | - | What the server does | "GitHub repository management and code analysis" |
| `category` | Yes | string | - | Server category for organization | "code", "knowledge", "cicd" |
| **Source Configuration** |
| `source.type` | Yes | enum | - | How to obtain the server | "registry" or "build" |
| `source.image` | Conditional | string | - | Image name (required for registry, tag for build) | "ghcr.io/github/github-mcp-server" |
| `source.repository` | Conditional | string | - | Git repo URL (required for build) | "https://github.com/org/repo.git" |
| `source.build_context` | No | string | "." | Docker build context directory | ".", "src/" |
| `source.dockerfile` | No | string | "Dockerfile" | Path to Dockerfile from build_context | "Dockerfile", "docker/Dockerfile" |
| **Runtime Configuration** |
| `environment_variables` | No | string[] | [] | Required environment variables (names only) | ["GITHUB_TOKEN", "API_KEY"] |
| `volumes` | No | string[] | [] | Volume mount specifications | ["VAULT_PATH:/vault:ro"] |
| `startup_timeout` | No | number | 30 | Seconds to wait for server startup | 20, 60 |
| **Health Checks** |
| `health_test.type` | No | enum | - | Type of health check | "stdio_jsonrpc", "json" |
| `health_test.method` | No | string | - | JSONRPC method name | "initialize" |
| `health_test.params` | No | object | - | Parameters for health check | `{protocolVersion: "2024-11-05"}` |
| `health_test.expected_response` | No | object | - | Expected response structure | `{jsonrpc: "2.0"}` |

## Complete Examples

### Example 1: GitHub MCP Server (Registry Image)

```yaml
servers:
  github:
    # Required fields
    name: GitHub MCP Server
    description: "GitHub repository management and code analysis"
    category: "code"

    # Source: Pull from registry
    source:
      type: registry
      image: ghcr.io/github/github-mcp-server

    # Environment configuration
    environment_variables:
      - "GITHUB_PERSONAL_ACCESS_TOKEN"

    # Health check (optional - can verify server starts)
    health_test:
      type: stdio_jsonrpc
      method: "initialize"
      params:
        protocolVersion: "2024-11-05"
        capabilities: {}
        clientInfo:
          name: "health_checker"
          version: "1.0.0"
      expected_response:
        jsonrpc: "2.0"
        result:
          protocolVersion: "2024-11-05"
```

### Example 2: Obsidian MCP Server (Build from Source)

```yaml
servers:
  obsidian:
    # Required fields
    name: "Obsidian MCP Server"
    description: |
      Comprehensive Obsidian vault management with tools for reading, writing, searching,
      and managing notes, tags, and frontmatter through the Local REST API plugin
    category: "knowledge"

    # Source: Build from GitHub repository
    source:
      type: build
      repository: "https://github.com/cyanheads/obsidian-mcp-server.git"
      build_context: "."
      image: "local/obsidian-mcp-server:latest"

    # Environment configuration
    environment_variables:
      - "OBSIDIAN_API_KEY"
      - "OBSIDIAN_BASE_URL"
      - "OBSIDIAN_VERIFY_SSL"
      - "OBSIDIAN_ENABLE_CACHE"

    # Extended timeout for cache building
    startup_timeout: 20

    # Health check using stdio JSONRPC protocol
    health_test:
      type: "stdio_jsonrpc"
      method: "initialize"
      params:
        protocolVersion: "2024-11-05"
        capabilities: {}
        clientInfo:
          name: "health_checker"
          version: "1.0.0"
      expected_response:
        jsonrpc: "2.0"
        result:
          protocolVersion: "2024-11-05"
          serverInfo:
            name: "obsidian-mcp-server"
```

## Comparison: Old vs New Schema

### What Was Simplified

| Original Field | MVP Status | Rationale |
|---------------|------------|-----------|
| `server_type` | **REMOVED** | Not needed for MVP - can be inferred from configuration |
| `capabilities` | **REMOVED** | Server introspection will provide this, not registry metadata |
| `features` | **REMOVED** | Duplicate of capabilities, not essential for MVP |
| `placeholders` | **REMOVED** | .env handling is responsibility of deployment tool, not registry |
| `health_test.parse_mode` | **SIMPLIFIED** | Consolidated into `health_test.type` |
| `health_test.path` | **REMOVED** | HTTP health checks not needed for MVP (stdio only) |
| `health_test.expected_status` | **REMOVED** | HTTP-specific, not needed for stdio checks |
| `networks` | **REMOVED** | Advanced Docker feature, use host network for MVP |
| `cmd`/`entrypoint` | **REMOVED** | Should be in Dockerfile, not registry |
| `source.entrypoint` | **REMOVED** | Advanced feature, not needed for MVP |
| `source.cmd` | **REMOVED** | Advanced feature, not needed for MVP |

### What Was Kept

| Field | Reason |
|-------|--------|
| `name` | Essential for identification |
| `description` | User-facing documentation |
| `category` | Organization and filtering |
| `source.*` | Core functionality - where to get the server |
| `environment_variables` | Required for server configuration |
| `volumes` | Needed for Obsidian vault access |
| `health_test` | Verify server starts correctly |
| `startup_timeout` | Some servers (Obsidian) need more time |

### Key Differences

1. **Simplified source configuration**: Reduced from multiple build strategy options to just "registry" or "build"
2. **Environment variables simplified**: Only list names, actual values come from .env file
3. **Health checks streamlined**: Focus on stdio_jsonrpc (MCP standard), removed HTTP checks
4. **Removed Docker complexity**: No custom networks, commands, entrypoints - use defaults
5. **Category-based organization**: Single category field instead of server_type taxonomy

## Migration Path from Old Schema

### Converting GitHub Server

**Old Schema:**
```yaml
github:
  name: GitHub MCP Server
  server_type: "api_based"
  description: "GitHub repository management"
  category: "code"
  source:
    type: registry
    image: ghcr.io/github/github-mcp-server
  environment_variables:
    - "GITHUB_PERSONAL_ACCESS_TOKEN"
  health_test:
    parse_mode: json
    path: "/health"
    expected_status: 200
    expected_response:
      status: "ok"
  capabilities:
    - "repository_management"
    - "issue_tracking"
```

**New MVP Schema:**
```yaml
github:
  name: GitHub MCP Server
  description: "GitHub repository management"
  category: "code"
  source:
    type: registry
    image: ghcr.io/github/github-mcp-server
  environment_variables:
    - "GITHUB_PERSONAL_ACCESS_TOKEN"
  # Health check removed (not essential for MVP)
  # capabilities removed (introspected from server)
```

### Converting Obsidian Server

**Old Schema:**
```yaml
obsidian:
  name: "Obsidian MCP Server"
  server_type: "api_based"
  description: "Obsidian vault management"
  category: "knowledge"
  startup_timeout: 20
  source:
    type: build
    repository: "https://github.com/cyanheads/obsidian-mcp-server.git"
    image: "local/obsidian-mcp-server:latest"
    build_context: "."
  environment_variables:
    - "OBSIDIAN_API_KEY"
    - "OBSIDIAN_BASE_URL"
    - "OBSIDIAN_VERIFY_SSL"
    - "OBSIDIAN_ENABLE_CACHE"
  health_test:
    type: "stdio_jsonrpc"
    method: "initialize"
    params:
      protocolVersion: "2024-11-05"
      capabilities: {}
      clientInfo:
        name: "health_checker"
        version: "1.0.0"
    expected_response:
      jsonrpc: "2.0"
      result:
        protocolVersion: "2024-11-05"
        serverInfo:
          name: "obsidian-mcp-server"
  capabilities:
    - "note_management"
    - "vault_search"
```

**New MVP Schema:**
```yaml
obsidian:
  name: "Obsidian MCP Server"
  description: "Obsidian vault management with reading, writing, searching, and tag operations"
  category: "knowledge"
  startup_timeout: 20
  source:
    type: build
    repository: "https://github.com/cyanheads/obsidian-mcp-server.git"
    image: "local/obsidian-mcp-server:latest"
    build_context: "."
  environment_variables:
    - "OBSIDIAN_API_KEY"
    - "OBSIDIAN_BASE_URL"
    - "OBSIDIAN_VERIFY_SSL"
    - "OBSIDIAN_ENABLE_CACHE"
  health_test:
    type: "stdio_jsonrpc"
    method: "initialize"
    params:
      protocolVersion: "2024-11-05"
      capabilities: {}
      clientInfo:
        name: "health_checker"
        version: "1.0.0"
    expected_response:
      jsonrpc: "2.0"
      result:
        protocolVersion: "2024-11-05"
        serverInfo:
          name: "obsidian-mcp-server"
  # capabilities removed (same as old schema)
```

## Future Extensions (Post-MVP)

### Phase 2: Advanced Docker Features

```yaml
servers:
  advanced-server:
    # ... MVP fields ...

    # Advanced Docker configuration
    docker:
      entrypoint: ["/custom-entrypoint.sh"]
      cmd: ["--flag", "value"]
      networks:
        - "custom-network"
      privileged: true
      capabilities:
        add: ["SYS_ADMIN"]
        drop: ["NET_RAW"]
```

### Phase 3: Multi-Platform Support

```yaml
servers:
  multiplatform-server:
    # ... MVP fields ...

    # Platform-specific configurations
    platforms:
      linux/amd64:
        source:
          image: "server:amd64"
      linux/arm64:
        source:
          image: "server:arm64"
```

### Phase 4: Capability Introspection

```yaml
servers:
  introspectable-server:
    # ... MVP fields ...

    # Capability discovery
    capabilities:
      introspect: true
      cache_duration: 3600
      fallback:
        - "basic_operations"
        - "read_only"
```

### Phase 5: Advanced Health Checks

```yaml
servers:
  monitored-server:
    # ... MVP fields ...

    # Enhanced health monitoring
    health_test:
      type: "composite"
      checks:
        - type: "stdio_jsonrpc"
          method: "initialize"
        - type: "http"
          url: "http://localhost:3000/health"
        - type: "tcp"
          port: 3000
      interval: 30
      retries: 3
      failure_action: "restart"
```

### Phase 6: Dependency Management

```yaml
servers:
  dependent-server:
    # ... MVP fields ...

    # Server dependencies
    dependencies:
      required:
        - "postgres-mcp"
        - "redis-mcp"
      optional:
        - "cache-mcp"

    # Startup ordering
    startup_order: 10
```

## Validation Rules

### Required Field Validation

```bash
# Server must have these fields
- name (non-empty string)
- description (non-empty string)
- category (non-empty string)
- source.type (enum: registry|build)

# Conditional requirements
if source.type == "registry":
  - source.image (non-empty string)

if source.type == "build":
  - source.repository (valid Git URL)
  - source.image (non-empty string, local tag)
```

### Field Format Validation

```bash
# Image name format
source.image: ^[a-z0-9._/-]+:[a-z0-9._-]+$
  Valid: "ghcr.io/org/image:latest", "local/image:v1.0"
  Invalid: "IMAGE:TAG", "image", "image:"

# Repository URL format
source.repository: ^https://[a-z0-9.-]+/[a-z0-9_.-]+/[a-z0-9_.-]+\.git$
  Valid: "https://github.com/user/repo.git"
  Invalid: "http://...", "git@...", "github.com/user/repo"

# Environment variable names
environment_variables[]: ^[A-Z_][A-Z0-9_]*$
  Valid: "API_KEY", "GITHUB_TOKEN", "MY_VAR_123"
  Invalid: "api-key", "123VAR", "my var"

# Volume format
volumes[]: ^([A-Z_][A-Z0-9_]*|/[a-z0-9/_.-]+):/[a-z0-9/_.-]+(:(ro|rw))?$
  Valid: "VAULT_PATH:/vault:ro", "/data:/app/data:rw"
  Invalid: "vault:/vault", "/data:rw", "DATA:/data:rx"

# Category
category: ^[a-z_]+$
  Valid: "code", "knowledge", "infrastructure"
  Invalid: "Code", "code-review", "code review"
```

## Implementation Notes

### Parsing Strategy

```bash
# Use yq for YAML parsing
yq eval '.servers.github.name' registry.yml
yq eval '.servers.github.source.type' registry.yml

# Validate required fields
validate_server() {
  local server=$1

  # Check required fields
  [[ -n $(yq ".servers.$server.name" registry.yml) ]] || die "Missing name"
  [[ -n $(yq ".servers.$server.description" registry.yml) ]] || die "Missing description"
  [[ -n $(yq ".servers.$server.category" registry.yml) ]] || die "Missing category"

  # Check source configuration
  local source_type=$(yq ".servers.$server.source.type" registry.yml)
  if [[ "$source_type" == "registry" ]]; then
    [[ -n $(yq ".servers.$server.source.image" registry.yml) ]] || die "Missing source.image"
  elif [[ "$source_type" == "build" ]]; then
    [[ -n $(yq ".servers.$server.source.repository" registry.yml) ]] || die "Missing source.repository"
    [[ -n $(yq ".servers.$server.source.image" registry.yml) ]] || die "Missing source.image"
  else
    die "Invalid source.type: $source_type"
  fi
}
```

### Environment Variable Handling

```bash
# Read environment variables from registry
get_env_vars() {
  local server=$1
  yq ".servers.$server.environment_variables[]" registry.yml
}

# Generate docker run environment flags
generate_env_flags() {
  local server=$1
  local env_vars=$(get_env_vars "$server")

  for var in $env_vars; do
    if [[ -z "${!var}" ]]; then
      echo "Warning: $var not set in environment" >&2
    else
      echo -n "-e $var "
    fi
  done
}
```

### Volume Mounting

```bash
# Parse volume specification
parse_volume() {
  local volume_spec=$1

  # Format: ENV_VAR:/container/path:mode or /host/path:/container/path:mode
  if [[ "$volume_spec" =~ ^([A-Z_][A-Z0-9_]*):(.+)$ ]]; then
    # Environment variable reference
    local env_var="${BASH_REMATCH[1]}"
    local container_path="${BASH_REMATCH[2]}"
    local host_path="${!env_var}"

    if [[ -z "$host_path" ]]; then
      die "$env_var not set in environment"
    fi

    echo "$host_path:$container_path"
  else
    # Direct path specification
    echo "$volume_spec"
  fi
}
```

## Schema Version

- **Version**: 1.0.0-mvp
- **Compatibility**: Subset of MacbookSetup registry schema
- **Migration**: Backwards compatible (old fields ignored)
- **Next Version**: 1.1.0 (add capabilities, HTTP health checks)

---

**Document Version**: 1.0.0
**Last Updated**: 2025-10-04
**Status**: MVP - Ready for Implementation
