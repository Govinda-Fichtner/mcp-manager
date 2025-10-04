# MCP Manager - System Architecture

## 1. System Overview

MCP Manager is a unified tool for managing Model Context Protocol (MCP) servers through Docker containerization. It provides a centralized registry, automated builds, and multi-platform configuration generation.

**Design Approach:** This architecture follows the **MacbookSetup proven pattern** - monolithic script initially, Jinja2 templates from day 1, stateless design, and gradual modularization as complexity grows. See `docs/file-structure.md` for detailed rationale on why we chose this approach over a fully modular structure from the start.

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MCP Manager System                          │
│                                                                     │
│  ┌────────────────┐                                                │
│  │   CLI Layer    │                                                │
│  │ mcp-manager.sh │                                                │
│  └────────┬───────┘                                                │
│           │                                                        │
│           ├──────┬──────────┬───────────┬──────────┬──────────┐  │
│           │      │          │           │          │          │  │
│  ┌────────▼─┐ ┌──▼─────┐ ┌─▼────────┐ ┌▼────────┐ ┌▼────────┐ │  │
│  │  build   │ │  pull  │ │  config  │ │  info   │ │ health  │ │  │
│  │ Command  │ │Command │ │ Command  │ │Command  │ │Command  │ │  │
│  └────┬─────┘ └───┬────┘ └────┬─────┘ └────┬────┘ └────┬────┘ │  │
│       │           │            │            │           │      │  │
│  ┌────▼───────────▼────────────▼────────────▼───────────▼────┐ │  │
│  │                    Core Components                         │ │  │
│  │  ┌──────────────┐  ┌───────────────┐  ┌────────────────┐  │ │  │
│  │  │   Registry   │  │Configuration  │  │     State      │  │ │  │
│  │  │   Parser     │  │   Generator   │  │    Manager     │  │ │  │
│  │  └──────┬───────┘  └───────┬───────┘  └────────┬───────┘  │ │  │
│  │         │                  │                    │          │ │  │
│  │         │                  │                    │          │ │  │
│  │  ┌──────▼──────────────────▼────────────────────▼───────┐  │ │  │
│  │  │           Docker Integration Layer                   │  │ │  │
│  │  │  • Container Builder  • Image Puller                 │  │ │  │
│  │  │  • Volume Manager     • Network Configurator         │  │ │  │
│  │  │  • Health Monitor                                    │  │ │  │
│  │  └─────────────────────────┬────────────────────────────┘  │ │  │
│  └────────────────────────────┼─────────────────────────────┘ │  │
│                               │                               │  │
└───────────────────────────────┼───────────────────────────────┘  │
                                │                                  │
                    ┌───────────▼───────────┐                      │
                    │   Docker Engine       │                      │
                    │  • Containers         │                      │
                    │  • Images             │                      │
                    │  • Volumes            │                      │
                    │  • Networks           │                      │
                    └───────────┬───────────┘                      │
                                │                                  │
                    ┌───────────▼───────────┐                      │
                    │   MCP Servers         │                      │
                    │  • GitHub MCP         │                      │
                    │  • Obsidian MCP       │                      │
                    │  • Custom MCPs        │                      │
                    └───────────────────────┘                      │
```

### Component Interaction Flow

```
User Command Flow:
─────────────────

1. User Input
   │
   ▼
2. mcp-manager.sh (Main Entry Point)
   │
   ├─► Parse Arguments
   │   └─► Validate Subcommand
   │
   ├─► Load Environment (.env)
   │   └─► Set Global Variables
   │
   ├─► Load Registry (mcp_server_registry.yml)
   │   └─► Parse YAML → Internal Data Structure
   │
   ▼
3. Command Dispatcher
   │
   ├─► build   → Docker Builder   → Container
   ├─► pull    → Image Puller     → Local Image
   ├─► config  → Config Generator → JSON/YAML Files
   ├─► info    → Registry Reader  → Display Info
   └─► health  → Health Monitor   → Status Report
```

### Data Flow

```
Configuration Generation Flow:
─────────────────────────────

Registry (YAML)
   │
   ├─► Parse Server Metadata
   │   │
   │   ├─► Name
   │   ├─► Description
   │   ├─► Repository URL
   │   ├─► Build Strategy
   │   ├─► Environment Variables
   │   └─► Port Mappings
   │
   ▼
Template Engine
   │
   ├─► Select Format
   │   │
   │   ├─► Claude Desktop (JSON)
   │   ├─► Claude Code (JSON)
   │   └─► Gemini CLI (YAML)
   │
   ▼
Config Adapter
   │
   ├─► Transform Data
   │   │
   │   ├─► Map Fields
   │   ├─► Inject Paths
   │   └─► Add Metadata
   │
   ▼
Output Generator
   │
   ├─► Full Config Mode
   │   └─► Complete config.json
   │
   └─► Snippet Mode
       └─► Merge-ready fragment
```

## 2. Components

### A. mcp-manager.sh (Core Script)

**Purpose**: Main orchestration script providing CLI interface and command routing.

**Responsibilities**:
- Command-line argument parsing
- Environment initialization
- Command dispatching
- Error handling and logging
- User interaction

**Interfaces**:

```bash
# Public CLI Interface
mcp-manager.sh build <server-name> [--no-cache]
mcp-manager.sh pull <server-name> [--platform linux/amd64]
mcp-manager.sh config <format> [--snippet|--full] [--server <name>]
mcp-manager.sh info <server-name>
mcp-manager.sh health [server-name]

# Internal Functions
parse_registry()           # Returns: associative array of server configs
dispatch_command()         # Routes to appropriate handler
validate_server_name()     # Checks if server exists in registry
load_environment()         # Sources .env file
```

**Key Features**:
- Dependency checking (docker, yq, jq)
- Auto-completion support
- Verbose/debug logging modes
- Graceful error handling
- Help text generation

### B. mcp_server_registry.yml

**Purpose**: Centralized metadata repository for all MCP servers.

**Schema Definition**:

```yaml
servers:
  <server-name>:
    description: string          # Human-readable description
    repo: string                 # Git repository URL
    build_strategy: enum         # "dockerfile" | "compose" | "pull"
    dockerfile_path: string      # Relative path to Dockerfile (optional)
    image: string                # Pre-built image name (for pull strategy)
    tag: string                  # Image tag (default: latest)
    env:                         # Environment variables
      <VAR_NAME>: string
    ports:                       # Port mappings
      - "host:container"
    volumes:                     # Volume mounts
      - "host:container:mode"
    network_mode: string         # Docker network mode (default: host)
    command: string              # Override container command (optional)
    health_check:                # Health check configuration
      endpoint: string           # HTTP endpoint to check
      interval: number           # Check interval in seconds
      timeout: number            # Timeout in seconds
```

**Example Entries**:

```yaml
servers:
  github:
    description: "GitHub API integration for MCP"
    repo: "https://github.com/modelcontextprotocol/servers.git"
    build_strategy: "dockerfile"
    dockerfile_path: "src/github/Dockerfile"
    env:
      GITHUB_TOKEN: "${GITHUB_TOKEN}"
    ports:
      - "3000:3000"
    volumes:
      - "./data/github:/data:rw"
    network_mode: "host"
    health_check:
      endpoint: "http://localhost:3000/health"
      interval: 30
      timeout: 10

  obsidian:
    description: "Obsidian vault integration for MCP"
    repo: "https://github.com/modelcontextprotocol/servers.git"
    build_strategy: "dockerfile"
    dockerfile_path: "src/obsidian/Dockerfile"
    env:
      OBSIDIAN_VAULT_PATH: "${OBSIDIAN_VAULT_PATH}"
    volumes:
      - "${OBSIDIAN_VAULT_PATH}:/vault:ro"
    network_mode: "host"
    health_check:
      endpoint: "http://localhost:3001/health"
      interval: 30
      timeout: 10

  sqlite:
    description: "SQLite database integration"
    repo: "https://github.com/modelcontextprotocol/servers.git"
    build_strategy: "dockerfile"
    dockerfile_path: "src/sqlite/Dockerfile"
    env:
      SQLITE_DB_PATH: "${SQLITE_DB_PATH:-/data/db.sqlite}"
    volumes:
      - "./data/sqlite:/data:rw"
    network_mode: "host"
```

**Data Contracts**:
- All servers MUST have: `description`, `repo`, `build_strategy`
- Dockerfile strategy REQUIRES: `dockerfile_path`
- Pull strategy REQUIRES: `image`
- Environment variables use `${VAR}` for .env substitution

### C. Docker Integration Layer

**Purpose**: Abstraction layer for all Docker operations.

**Components**:

#### 1. Container Builder (`lib/docker.sh::build_container()`)

```bash
# Interface
build_container(server_name, no_cache=false)

# Workflow
1. Clone repository → /tmp/mcp-build-<server>
2. Copy Dockerfile → dockerfiles/<server>/
3. Substitute environment variables
4. Run: docker build -t mcp-<server>:latest
5. Tag with timestamp: mcp-<server>:<timestamp>
6. Clean up temporary files
7. Update state registry

# Returns: exit code (0=success, 1=failure)
```

#### 2. Image Puller (`lib/docker.sh::pull_image()`)

```bash
# Interface
pull_image(server_name, platform="linux/amd64")

# Workflow
1. Read image name from registry
2. Run: docker pull --platform <platform> <image>:<tag>
3. Tag as: mcp-<server>:latest
4. Update state registry

# Returns: exit code
```

#### 3. Volume Manager (`lib/docker.sh::setup_volumes()`)

```bash
# Interface
setup_volumes(server_name)

# Workflow
1. Parse volume definitions from registry
2. Create host directories if missing
3. Set permissions (read/write modes)
4. Validate mount points exist
5. Return volume args for docker run

# Returns: space-separated volume flags
# Example: "-v /data/github:/data:rw -v /logs:/logs:ro"
```

#### 4. Network Configurator (`lib/docker.sh::configure_network()`)

```bash
# Interface
configure_network(server_name)

# Workflow
1. Read network_mode from registry (default: host)
2. For bridge mode:
   - Create mcp-network if not exists
   - Return --network mcp-network
3. For host mode:
   - Return --network host
4. Parse port mappings
5. Return network + port flags

# Returns: network configuration flags
```

#### 5. Health Monitor (`lib/docker.sh::check_health()`)

```bash
# Interface
check_health(server_name)

# Workflow
1. Check if container is running
2. Read health_check config from registry
3. Curl health endpoint with timeout
4. Parse response (200 OK = healthy)
5. Check Docker container health status
6. Return combined health state

# Returns: JSON health report
{
  "server": "github",
  "container_status": "running",
  "health_endpoint": "healthy",
  "uptime": "2h 15m",
  "last_check": "2025-10-04T10:30:00Z"
}
```

### D. Configuration Layer

**Purpose**: Generate platform-specific configuration files for MCP clients using **Jinja2 templates** (following MacbookSetup proven pattern).

#### 1. Template Engine (Jinja2-based)

**Templates Directory Structure** (MacbookSetup pattern):
```
support/templates/
├── mcp_config.tpl              # Main template
├── github.tpl                  # Per-server templates
├── obsidian.tpl
└── [server].tpl
```

**Why Jinja2 from Day 1:**
- **Proven in MacbookSetup**: Already working in production with 20+ templates
- **Powerful Logic**: Supports conditionals, loops, includes - impossible with simple variable substitution
- **Template Includes**: Main template can include server-specific templates
- **No Custom Parsing**: Leverages battle-tested Python templating engine

**Template Variables** (Jinja2 context):
```jinja2
{{ server.id }}              # Server identifier
{{ server.name }}            # Human-readable name
{{ server.image }}           # Docker image name
{{ server.env_file }}        # Absolute path to .env
{{ server.volumes }}         # Array of volume mounts
{{ server.server_type }}     # api_based|mount_based|privileged
{{ server.container_args }}  # Additional CMD arguments
```

#### 2. Format Adapters

**Claude Desktop Adapter** (`lib/config.sh::generate_claude_desktop()`):

```json
{
  "mcpServers": {
    "{{SERVER_NAME}}": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "--network", "host",
        "-v", "{{VOLUME_MOUNTS}}",
        "-e", "{{ENV_VARS}}",
        "mcp-{{SERVER_NAME}}:latest"
      ],
      "env": {
        "{{ENV_KEY}}": "{{ENV_VALUE}}"
      }
    }
  }
}
```

**Claude Code Adapter** (`lib/config.sh::generate_claude_code()`):

```json
{
  "mcp": {
    "servers": {
      "{{SERVER_NAME}}": {
        "type": "docker",
        "image": "mcp-{{SERVER_NAME}}:latest",
        "network": "host",
        "volumes": [
          "{{VOLUME_MOUNTS}}"
        ],
        "environment": {
          "{{ENV_KEY}}": "{{ENV_VALUE}}"
        }
      }
    }
  }
}
```

**Gemini CLI Adapter** (`lib/config.sh::generate_gemini_cli()`):

```yaml
mcp_servers:
  - name: {{SERVER_NAME}}
    description: {{DESCRIPTION}}
    type: docker
    image: mcp-{{SERVER_NAME}}:latest
    network_mode: host
    volumes:
      - {{VOLUME_MOUNTS}}
    environment:
      {{ENV_KEY}}: {{ENV_VALUE}}
    health_check:
      endpoint: {{HEALTH_ENDPOINT}}
      interval: 30s
```

#### 3. Snippet Generator (`lib/config.sh::generate_snippet()`)

**Purpose**: Generate merge-ready configuration fragments.

**Output Format**:
```bash
# Usage: Append to existing config file
# For Claude Desktop: Add to ~/.config/claude-desktop/config.json "mcpServers" section
# For Claude Code: Add to .claude-code.json "mcp.servers" section
# For Gemini CLI: Add to gemini-config.yaml "mcp_servers" array

# Generated snippet:
<formatted config fragment>
```

#### 4. Full Config Merger (`lib/config.sh::merge_full_config()`)

**Workflow**:
1. Read existing config file (if exists)
2. Parse JSON/YAML structure
3. Merge new server entries
4. Preserve existing servers
5. Validate schema
6. Write updated config
7. Create backup (.bak)

### E. State Management (Stateless Design)

**Purpose**: Track minimal runtime state, following MacbookSetup's stateless pattern.

**State File**: `mcp.json` (lightweight, not `.mcp-manager-state.json`)

**Design Philosophy:**
- **Stateless like MacbookSetup**: No version history, no rollback tracking
- **Query Docker Directly**: Use `docker images`, `docker ps` for real-time state
- **No State Corruption**: Less state = fewer failure modes
- **Remove & Rebuild**: Instead of rollback, users remove and rebuild with different version

**Minimal Schema** (if state file used at all):
```json
{
  "version": "1.0.0",
  "servers": {
    "github": {
      "image": "ghcr.io/github/github-mcp-server:latest",
      "last_setup": "2025-10-04T10:30:00Z"
    }
  }
}
```

**State Queries** (direct Docker, no file):
```bash
# Check if image exists
docker images | grep -q "$(echo "$image" | cut -d: -f1)"

# Check if container running
docker ps | grep -q "$server_name"

# Get image details
docker inspect "$image" --format '{{.Created}}'
```

**No Rollback Feature**:
- Previous versions not tracked
- Users manually remove (`docker rmi`) and re-pull if they want different version
- Simpler implementation, fewer edge cases
- Matches MacbookSetup proven approach

## 3. Key Workflows

### Workflow 1: Adding a New Server

```
┌─────────────────────────────────────────────────────────┐
│                 Add New MCP Server                      │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────┐
         │ 1. Edit Registry YAML     │
         │    Add server definition  │
         └───────────┬───────────────┘
                     │
                     ▼
         ┌───────────────────────────┐
         │ 2. Create Dockerfile      │
         │    dockerfiles/<server>/  │
         └───────────┬───────────────┘
                     │
                     ▼
         ┌───────────────────────────┐
         │ 3. Set Environment Vars   │
         │    Update .env file       │
         └───────────┬───────────────┘
                     │
                     ▼
         ┌───────────────────────────┐
         │ 4. Test Build             │
         │    mcp-manager.sh build   │
         └───────────┬───────────────┘
                     │
                     ├─► Build Failed ──┐
                     │                  │
                     ▼                  ▼
         ┌───────────────────┐   ┌──────────────┐
         │ 5. Test Health    │   │ Debug Logs   │
         │    Check endpoint │   │ Fix Issues   │
         └───────────┬───────┘   └──────┬───────┘
                     │                  │
                     ▼                  │
         ┌───────────────────┐          │
         │ 6. Generate Config│          │
         │    Add to client  │          │
         └───────────┬───────┘          │
                     │                  │
                     ▼                  │
         ┌───────────────────┐          │
         │ 7. Verify Service │          │
         │    Test MCP calls │◄─────────┘
         └───────────────────┘
```

### Workflow 2: Building from Source

```
┌────────────┐
│ User Input │ mcp-manager.sh build github
└──────┬─────┘
       │
       ▼
┌──────────────────┐
│ Parse Arguments  │
│ • server=github  │
│ • no-cache=false │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Load Registry    │
│ • Parse YAML     │
│ • Find 'github'  │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Validate Config  │
│ • Check fields   │
│ • Verify repo    │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Clone Repository │
│ git clone <repo> │
│ → /tmp/build     │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Copy Dockerfile  │
│ • Get path       │
│ • Copy to build  │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Substitute Vars  │
│ • Replace ${VAR} │
│ • From .env      │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Docker Build     │
│ docker build     │
│ -t mcp-github    │
└─────┬────────────┘
      │
      ├─► Success ────────┐
      │                   │
      ▼                   ▼
┌──────────────┐   ┌─────────────┐
│ Tag Image    │   │ Update State│
│ :latest      │   │ Registry    │
│ :timestamp   │   │             │
└──────┬───────┘   └─────────────┘
       │
       ▼
┌──────────────┐
│ Cleanup Temp │
│ rm -rf /tmp  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Report Done  │
│ Image ready  │
└──────────────┘
```

### Workflow 3: Generating Configuration

```
User Request: mcp-manager.sh config claude-desktop --snippet --server github
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│                   Config Generator                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌───────────────┐                                      │
│  │ Parse Options │                                      │
│  │ • format      │                                      │
│  │ • mode        │                                      │
│  │ • server      │                                      │
│  └───────┬───────┘                                      │
│          │                                               │
│          ▼                                               │
│  ┌───────────────┐       ┌───────────────┐             │
│  │ Load Registry │──────►│ Filter Server │             │
│  │ All servers   │       │ github only   │             │
│  └───────────────┘       └───────┬───────┘             │
│                                   │                     │
│                                   ▼                     │
│                          ┌────────────────┐             │
│                          │ Load Template  │             │
│                          │ claude-desktop │             │
│                          └────────┬───────┘             │
│                                   │                     │
│                                   ▼                     │
│                          ┌────────────────┐             │
│                          │ Transform Data │             │
│                          │ • Map fields   │             │
│                          │ • Build args   │             │
│                          │ • Add env vars │             │
│                          └────────┬───────┘             │
│                                   │                     │
│                                   ▼                     │
│                          ┌────────────────┐             │
│                          │ Render Config  │             │
│                          │ JSON output    │             │
│                          └────────┬───────┘             │
│                                   │                     │
│  ┌────────────────────────────────┼─────────┐          │
│  │                                │         │          │
│  ▼                                ▼         ▼          │
│ ┌──────────┐              ┌──────────┐  ┌──────────┐  │
│ │ Snippet  │              │   Full   │  │  Stdout  │  │
│ │   Mode   │              │   Mode   │  │   Mode   │  │
│ └────┬─────┘              └────┬─────┘  └────┬─────┘  │
│      │                         │             │        │
│      ▼                         ▼             ▼        │
│ ┌─────────────┐         ┌─────────────┐  ┌─────────┐ │
│ │ Print Merge │         │ Read Existing│ │ Display │ │
│ │ Instructions│         │ Config File  │ │ to User │ │
│ └──────┬──────┘         └──────┬──────┘  └─────────┘ │
│        │                       │                      │
│        ▼                       ▼                      │
│ ┌─────────────┐         ┌─────────────┐              │
│ │   Output    │         │ Merge Data  │              │
│ │  Fragment   │         │ Servers     │              │
│ └─────────────┘         └──────┬──────┘              │
│                                │                      │
│                                ▼                      │
│                         ┌─────────────┐              │
│                         │ Write File  │              │
│                         │ config.json │              │
│                         └─────────────┘              │
└─────────────────────────────────────────────────────┘
```

### Workflow 4: Health Checking

```
                    ┌─────────────────┐
                    │  Health Check   │
                    │   Initiated     │
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
    ┌───────────────────┐     ┌──────────────────┐
    │ Single Server     │     │ All Servers      │
    │ Specified         │     │ (No arg)         │
    └─────────┬─────────┘     └────────┬─────────┘
              │                        │
              │                        │
              └────────────┬───────────┘
                           │
                           ▼
               ┌───────────────────────┐
               │   For Each Server     │
               └───────────┬───────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌──────────────┐
│ Container     │  │ HTTP Health   │  │ Docker       │
│ Running?      │  │ Endpoint      │  │ Health Status│
└───────┬───────┘  └───────┬───────┘  └──────┬───────┘
        │                  │                  │
        │ Yes              │ 200 OK           │ healthy
        ├─► PASS           ├─► PASS           ├─► PASS
        │                  │                  │
        │ No               │ Error            │ unhealthy
        └─► FAIL           └─► FAIL           └─► FAIL
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
        ▼                                     ▼
┌───────────────┐                    ┌────────────────┐
│ All Healthy   │                    │ Some Failed    │
│ Return 0      │                    │ Return 1       │
│               │                    │ • Log errors   │
│ ┌──────────┐  │                    │ • Suggest fix  │
│ │ Status:  │  │                    │ ┌───────────┐  │
│ │ ✓ github │  │                    │ │ Status:   │  │
│ │ ✓obsidian│  │                    │ │ ✓ github  │  │
│ │ ✓ sqlite │  │                    │ │ ✗obsidian │  │
│ └──────────┘  │                    │ │   (down)  │  │
└───────────────┘                    │ └───────────┘  │
                                     └────────────────┘

State Transitions:
─────────────────

  ┌──────────┐
  │ Unknown  │ Initial state
  └────┬─────┘
       │ First check
       ▼
  ┌──────────┐
  │ Starting │ Container launching
  └────┬─────┘
       │ Health endpoint responds
       ▼
  ┌──────────┐
  │ Healthy  │◄────┐ Continuous monitoring
  └────┬─────┘     │
       │           │
       │ Check fail│ Recovery
       ▼           │
  ┌──────────┐    │
  │Unhealthy │────┘
  └────┬─────┘
       │ Multiple failures
       ▼
  ┌──────────┐
  │  Failed  │ Manual intervention needed
  └──────────┘
```

## 4. File Structure

**Note:** Following the proven MacbookSetup pattern (see `docs/file-structure.md` for detailed rationale), we use a **monolithic initially, gradually modularized** approach rather than a fully modular library structure from day 1.

```
mcp-manager/
├── mcp_manager.sh                    # Main script (initially monolithic: 800-1200 lines)
│                                     # • All core functionality in single file initially
│                                     # • Gradually extract to lib/ as complexity grows
│                                     # • Argument parsing, command dispatch, core logic
│
├── mcp_server_registry.yml           # Server definitions (100-500 lines)
│                                     # • Server metadata
│                                     # • Build configurations
│                                     # • Environment mappings
│                                     # • Optimized schema (see registry-schema.md)
│
├── .env                              # Global environment variables
│   # GITHUB_TOKEN=ghp_xxx
│   # OBSIDIAN_VAULT_PATH=/path/to/vault
│   # OBSIDIAN_API_KEY=your_key_here
│   # DOCKER_REGISTRY=docker.io
│
├── mcp.json                          # Runtime state (lightweight, stateless design)
│                                     # • Current running containers only
│                                     # • No version history (stateless like MacbookSetup)
│                                     # • Minimal metadata
│
├── support/                          # Supporting files (MacbookSetup pattern)
│   ├── docker/                       # Custom Dockerfiles per server
│   │   ├── github/Dockerfile
│   │   ├── obsidian/Dockerfile
│   │   └── [server]/Dockerfile
│   │
│   ├── templates/                    # Jinja2 config templates
│   │   ├── mcp_config.tpl           # Main template
│   │   ├── github.tpl               # Per-server templates
│   │   ├── obsidian.tpl
│   │   └── [server].tpl
│   │
│   └── completions/                  # Shell completions (future)
│       └── _mcp_manager
│
├── lib/                              # Optional modules (extracted as needed)
│   # Note: Start with everything in mcp_manager.sh
│   # Extract to lib/ only when functions exceed 50 lines or used 3+ times
│   ├── docker.sh                     # Docker operations (when extracted)
│   ├── config.sh                     # Config generation (when extracted)
│   └── utils.sh                      # Shared utilities (when extracted)
│
├── spec/                             # Test suite (ShellSpec)
│   ├── spec_helper.sh                # Test framework setup
│   ├── test_helpers.sh               # Shared test utilities
│   │
│   ├── unit/                         # Fast tests (no Docker)
│   │   ├── mcp_manager_core_spec.sh
│   │   ├── registry_validation_spec.sh
│   │   ├── template_validation_spec.sh
│   │   └── config_generation_spec.sh
│   │
│   ├── integration/                  # Slower tests (real Docker)
│   │   ├── mcp_manager_integration_spec.sh
│   │   └── docker_workflow_spec.sh
│   │
│   └── fixtures/                     # Test data
│       ├── sample_registry.yml
│       ├── sample_config.json
│       └── sample.env
│
├── docs/                             # Documentation
│   ├── architecture.md               # This file
│   ├── file-structure.md             # File structure rationale
│   ├── registry-schema.md            # Registry schema details
│   ├── analysis.md                   # Implementation analysis
│   └── examples/                     # Usage examples
│       ├── adding-server.md
│       └── custom-dockerfile.md
│
├── tmp/                              # Temporary files (gitignored)
│   ├── repositories/                 # Cloned repos for building
│   └── test_home/                    # Test environment
│
├── README.md                         # Project overview
├── LICENSE                           # License file
├── CHANGELOG.md                      # Version history
└── .gitignore                        # Git ignore rules
```

**Key Differences from Original Proposal:**

1. **Monolithic Start**: Single `mcp_manager.sh` file (800-1200 lines) initially, not split into lib/ modules from day 1
2. **MacbookSetup Structure**: Uses `support/` directory pattern (proven in production)
3. **Stateless Design**: `mcp.json` instead of `.mcp-manager-state.json` - no version history or rollback tracking
4. **Jinja2 Templates**: Using `support/templates/` with `.tpl` extension (not `.tmpl`)
5. **ShellSpec Tests**: `spec/` directory (not `tests/`) following ShellSpec convention
6. **No Logs Directory**: Use system logs or tmp/, don't clutter project
7. **Gradual Modularization**: Extract to `lib/` only when complexity justifies (see file-structure.md)

## 5. Design Decisions

### 5.1 Why Bash?

**Rationale**:
- **Portability**: Works on any Unix-like system without additional runtime
- **Shell Scripting Natural Fit**: Docker, Git, and system commands are shell-native
- **Low Dependency**: Only requires bash, docker, yq, jq (commonly available)
- **Easy Installation**: Single script deployment, no compilation needed
- **Direct System Access**: No abstraction layers for file/process management
- **Rapid Prototyping**: Quick iteration on CLI tools

**Trade-offs**:
- Limited type safety (mitigated by shellcheck, strict mode)
- String manipulation can be verbose (mitigated by helper functions)
- Error handling requires discipline (`set -euo pipefail`)

### 5.2 Why YAML for Registry?

**Rationale**:
- **Human-Readable**: Easy to edit manually without specialized tools
- **Widely Supported**: yq provides robust parsing/querying
- **Comments Support**: Inline documentation in config file
- **Hierarchical Structure**: Natural fit for nested server configs
- **Industry Standard**: Used by Docker Compose, Kubernetes, GitHub Actions

**Alternative Considered**: JSON
- Rejected due to lack of comments, harder manual editing

**Data Format**:
```yaml
# Comments allowed for documentation
servers:
  github:  # Server key
    description: "GitHub API integration"  # Inline comments
    repo: "https://github.com/..."
    # Nested structures
    env:
      TOKEN: "${GITHUB_TOKEN}"
```

### 5.3 Why Global .env File?

**Rationale**:
- **Single Source of Truth**: All secrets/variables in one place
- **Security**: Easy to gitignore, prevent accidental commits
- **Simplicity**: Standard pattern (dotenv) recognized by developers
- **Flexibility**: Environment-specific files (.env.production, .env.dev)
- **Docker Integration**: Direct pass-through to containers

**Security Measures**:
```bash
# .gitignore
.env
.env.*
!.env.example

# File permissions
chmod 600 .env

# Variable substitution with defaults
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
```

**Alternative Considered**: Per-server .env files
- Rejected due to complexity, harder to manage multiple secrets

### 5.4 Why Host Network Mode?

**Rationale**:
- **MCP Client Access**: Clients need to connect to server ports
- **Simplicity**: No port mapping conflicts, direct localhost access
- **Performance**: Eliminates network bridge overhead
- **Development Friendly**: Easy to curl/test endpoints

**Security Considerations**:
- Containers can access all host ports (mitigated by firewall rules)
- Production deployments should use bridge mode with explicit port mappings
- Document security implications in README

**Configurable**:
```yaml
# Override in registry for production
network_mode: "bridge"  # or "host" (default)
ports:
  - "3000:3000"  # Required for bridge mode
```

### 5.5 Why Mounted Volumes?

**Rationale**:
- **Data Persistence**: Survive container restarts
- **Direct File Access**: Read vaults, databases without copying
- **Performance**: No data serialization overhead
- **Development Workflow**: Edit files on host, see changes immediately

**Volume Types**:
```yaml
volumes:
  # Named volume (Docker-managed)
  - "github-data:/data:rw"

  # Bind mount (host path)
  - "${OBSIDIAN_VAULT_PATH}:/vault:ro"

  # Relative path (from project root)
  - "./data/sqlite:/db:rw"
```

**Permissions**:
- `:ro` - Read-only (Obsidian vault - prevent accidental writes)
- `:rw` - Read-write (database files, caches)

## 6. Extension Points

### 6.1 Adding New MCP Servers

**Process**:

1. **Update Registry**:
```yaml
# mcp_server_registry.yml
servers:
  my-custom-server:
    description: "My custom MCP integration"
    repo: "https://github.com/me/my-mcp-server.git"
    build_strategy: "dockerfile"
    dockerfile_path: "Dockerfile"
    env:
      CUSTOM_API_KEY: "${CUSTOM_API_KEY}"
    ports:
      - "4000:4000"
    volumes:
      - "./data/custom:/data:rw"
    network_mode: "host"
    health_check:
      endpoint: "http://localhost:4000/health"
      interval: 30
      timeout: 10
```

2. **Add Environment Variables**:
```bash
# .env
CUSTOM_API_KEY=your_key_here
```

3. **Optional: Custom Dockerfile**:
```bash
# dockerfiles/my-custom-server/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 4000
CMD ["node", "server.js"]
```

4. **Build and Test**:
```bash
./mcp-manager.sh build my-custom-server
./mcp-manager.sh health my-custom-server
```

### 6.2 Supporting New Config Formats

**Example: Adding VSCode MCP Extension Support**

1. **Create Template**:
```json
// templates/vscode-mcp.json.tmpl
{
  "mcp.servers": {
    "{{SERVER_NAME}}": {
      "transport": "docker",
      "image": "mcp-{{SERVER_NAME}}:latest",
      "environment": {{ENV_VARS}},
      "volumes": {{VOLUMES}}
    }
  }
}
```

2. **Add Generator Function**:
```bash
# lib/config.sh
generate_vscode_mcp() {
  local server_name="$1"
  local output_file="${2:-vscode-mcp.json}"

  # Load template
  local template="$(cat templates/vscode-mcp.json.tmpl)"

  # Get server config
  local server_config="$(get_server_config "$server_name")"

  # Transform data
  local env_vars="$(format_env_vars_json "$server_config")"
  local volumes="$(format_volumes_json "$server_config")"

  # Substitute variables
  template="${template//\{\{SERVER_NAME\}\}/$server_name}"
  template="${template//\{\{ENV_VARS\}\}/$env_vars}"
  template="${template//\{\{VOLUMES\}\}/$volumes}"

  # Output
  echo "$template" > "$output_file"
  log_info "Generated VSCode MCP config: $output_file"
}
```

3. **Register in Dispatcher**:
```bash
# mcp-manager.sh
case "$format" in
  claude-desktop) generate_claude_desktop "$@" ;;
  claude-code)    generate_claude_code "$@" ;;
  gemini-cli)     generate_gemini_cli "$@" ;;
  vscode-mcp)     generate_vscode_mcp "$@" ;;  # <-- Add here
  *)
    log_error "Unknown format: $format"
    exit 1
    ;;
esac
```

### 6.3 Custom Health Checks

**Current**: HTTP endpoint polling

**Extension Point**: Custom health check scripts

**Implementation**:

1. **Registry Schema Extension**:
```yaml
servers:
  postgres-mcp:
    # ... other config ...
    health_check:
      type: "script"  # New field
      script: "scripts/health/postgres-check.sh"
      interval: 30
      timeout: 10
```

2. **Health Check Dispatcher**:
```bash
# lib/docker.sh
check_health() {
  local server_name="$1"
  local health_type="$(yq ".servers.${server_name}.health_check.type" registry.yml)"

  case "$health_type" in
    http|"")
      check_health_http "$server_name"
      ;;
    script)
      local script="$(yq ".servers.${server_name}.health_check.script" registry.yml)"
      check_health_script "$server_name" "$script"
      ;;
    tcp)
      check_health_tcp "$server_name"
      ;;
    *)
      log_error "Unknown health check type: $health_type"
      return 1
      ;;
  esac
}
```

3. **Custom Script Example**:
```bash
# scripts/health/postgres-check.sh
#!/bin/bash
container_id="$(docker ps -q -f name=mcp-postgres)"
docker exec "$container_id" pg_isready -U postgres
exit $?
```

### 6.4 Platform-Specific Builds

**Use Case**: ARM64 vs AMD64, macOS vs Linux

**Current**: Single platform build

**Extension**:

1. **Registry Multi-Platform Config**:
```yaml
servers:
  github:
    # ... existing config ...
    platforms:
      - linux/amd64
      - linux/arm64
      - darwin/arm64
    build_args:
      linux/amd64:
        BASE_IMAGE: "node:20-alpine"
      linux/arm64:
        BASE_IMAGE: "node:20-alpine"
      darwin/arm64:
        BASE_IMAGE: "node:20"
```

2. **Build Command Enhancement**:
```bash
./mcp-manager.sh build github --platform linux/arm64
./mcp-manager.sh build github --all-platforms
```

3. **Multi-Arch Build Function**:
```bash
# lib/docker.sh
build_multiarch() {
  local server_name="$1"
  local platforms="$(yq ".servers.${server_name}.platforms[]" registry.yml | tr '\n' ',')"

  docker buildx create --use --name mcp-builder || true
  docker buildx build \
    --platform "$platforms" \
    --tag "mcp-${server_name}:latest" \
    --push \
    .
}
```

## 7. Interface Contracts

### 7.1 Registry Schema Contract

**Version**: 1.0.0

**Required Fields**:
- `servers.<name>.description` (string)
- `servers.<name>.repo` (string, valid Git URL)
- `servers.<name>.build_strategy` (enum: dockerfile|compose|pull)

**Conditional Requirements**:
- If `build_strategy=dockerfile`: MUST have `dockerfile_path`
- If `build_strategy=pull`: MUST have `image`

**Optional Fields**:
- `env` (object, key-value pairs)
- `ports` (array of strings, format: "host:container")
- `volumes` (array of strings, format: "host:container:mode")
- `network_mode` (string, default: "host")
- `command` (string, override container command)
- `health_check.endpoint` (string, HTTP URL)
- `health_check.interval` (number, seconds)
- `health_check.timeout` (number, seconds)

### 7.2 State File Contract

**Version**: 1.0.0

**Structure**:
```json
{
  "version": "1.0.0",
  "last_updated": "ISO8601 timestamp",
  "servers": {
    "<server-name>": {
      "image": "string",
      "image_id": "string (sha256:...)",
      "build_timestamp": "ISO8601 timestamp",
      "container_id": "string",
      "status": "enum(running|stopped|failed|unknown)",
      "health": {
        "status": "enum(healthy|unhealthy|starting|unknown)",
        "last_check": "ISO8601 timestamp",
        "consecutive_failures": "number"
      },
      "ports": ["string array"],
      "volumes": ["string array"],
      "uptime": "string (human-readable)"
    }
  },
  "registry_hash": "string (md5:...)",
  "docker_version": "string"
}
```

### 7.3 CLI Exit Codes

```bash
0   # Success
1   # General error
2   # Invalid arguments
3   # Missing dependency (docker, yq, jq)
4   # Server not found in registry
5   # Build failed
6   # Health check failed
7   # Configuration error
10  # Docker daemon not running
11  # Permission denied (Docker socket)
```

### 7.4 Environment Variable Contract

**Required**:
- None (all optional with defaults)

**Recommended**:
- `GITHUB_TOKEN` - For GitHub MCP server
- `OBSIDIAN_VAULT_PATH` - For Obsidian MCP server

**System**:
- `DOCKER_HOST` - Override Docker socket (default: unix:///var/run/docker.sock)
- `LOG_LEVEL` - Logging verbosity (debug|info|warn|error, default: info)
- `MCP_DATA_DIR` - Data directory (default: ./data)
- `MCP_LOG_DIR` - Log directory (default: ./logs)

## 8. Security Considerations

### 8.1 Secret Management

**Threats**:
- Accidental commit of .env to Git
- Secrets in container logs
- Secrets in state file

**Mitigations**:
```bash
# .gitignore enforcement
.env
.env.*
!.env.example
.mcp-manager-state.json

# File permissions
chmod 600 .env
chmod 600 .mcp-manager-state.json

# Scrub logs
log_command() {
  local cmd="$1"
  # Remove sensitive args before logging
  local safe_cmd="${cmd//$GITHUB_TOKEN/***REDACTED***}"
  log_debug "Running: $safe_cmd"
}
```

### 8.2 Container Isolation

**Current**: Host network mode reduces isolation

**Recommendations**:
- Use bridge mode in production
- Implement firewall rules
- Run containers as non-root user
- Use read-only root filesystem where possible

### 8.3 Input Validation

**Threats**: Command injection, path traversal

**Mitigations**:
```bash
# Validate server names (alphanumeric + dash only)
validate_server_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-zA-Z0-9-]+$ ]]; then
    log_error "Invalid server name: $name"
    exit 2
  fi
}

# Sanitize paths
sanitize_path() {
  local path="$1"
  # Remove .. traversal attempts
  path="${path//\.\./}"
  echo "$path"
}

# Quote all variables in commands
docker run --name "$(sanitize_name "$name")" ...
```

## 9. Performance Optimization

### 9.1 Build Caching

**Strategy**: Layer Docker build cache, reuse unchanged layers

```dockerfile
# Optimize Dockerfile layer order
FROM node:20-alpine
WORKDIR /app

# Cache dependencies (changes infrequently)
COPY package*.json ./
RUN npm ci --production

# Copy source (changes frequently)
COPY . .

CMD ["node", "server.js"]
```

### 9.2 Registry Parsing

**Current**: Parse YAML on every command

**Optimization**: Cache parsed registry in memory

```bash
# Global cache
declare -A REGISTRY_CACHE

parse_registry_cached() {
  local registry_file="mcp_server_registry.yml"
  local file_hash="$(md5sum "$registry_file" | cut -d' ' -f1)"

  if [[ "${REGISTRY_CACHE[hash]}" == "$file_hash" ]]; then
    # Return cached data
    echo "${REGISTRY_CACHE[data]}"
  else
    # Parse and cache
    local data="$(yq -o=json "$registry_file")"
    REGISTRY_CACHE[hash]="$file_hash"
    REGISTRY_CACHE[data]="$data"
    echo "$data"
  fi
}
```

### 9.3 Parallel Builds

**Use Case**: Build multiple servers simultaneously

```bash
./mcp-manager.sh build github obsidian sqlite --parallel

# Implementation
build_parallel() {
  local servers=("$@")
  local pids=()

  for server in "${servers[@]}"; do
    build_container "$server" &
    pids+=($!)
  done

  # Wait for all builds
  for pid in "${pids[@]}"; do
    wait "$pid" || log_error "Build failed for PID $pid"
  done
}
```

## 10. Future Enhancements

### 10.1 Plugin System

**Vision**: Third-party extensions without modifying core

**API**:
```bash
# plugins/my-plugin.sh
mcp_plugin_init() {
  register_command "my-command" "my_plugin_handler"
  register_hook "pre-build" "my_plugin_pre_build"
}

my_plugin_handler() {
  echo "Custom command executed!"
}
```

### 10.2 Web UI

**Vision**: Browser-based management interface

**Features**:
- Server status dashboard
- One-click builds
- Config editor
- Log viewer
- Health metrics graphs

### 10.3 Auto-Update

**Vision**: Self-updating script and server images

```bash
./mcp-manager.sh update --check
./mcp-manager.sh update --apply
./mcp-manager.sh update --servers  # Update all server images
```

### 10.4 Backup/Restore

**Vision**: Snapshot entire MCP environment

```bash
./mcp-manager.sh backup --output mcp-backup-2025-10-04.tar.gz
./mcp-manager.sh restore mcp-backup-2025-10-04.tar.gz
```

---

**Document Version**: 1.0.0
**Last Updated**: 2025-10-04
**Maintained By**: System Architect
