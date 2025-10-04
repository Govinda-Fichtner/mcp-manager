# Core Concepts: MCP Manager

## Table of Contents
1. [Model Context Protocol (MCP)](#1-model-context-protocol-mcp)
2. [Local vs Remote MCP Servers](#2-local-vs-remote-mcp-servers)
3. [Docker Isolation](#3-docker-isolation)
4. [Build Strategies](#4-build-strategies)
5. [Configuration Management](#5-configuration-management)
6. [State Tracking](#6-state-tracking)
7. [Testing Philosophy](#7-testing-philosophy)

---

## 1. Model Context Protocol (MCP)

### What is MCP?

The **Model Context Protocol (MCP)** is an open standard introduced by Anthropic in November 2024 to standardize how AI systems (like Large Language Models) integrate with external tools, data sources, and services.

**Think of MCP as the "USB-C of AI"**: Just as USB-C provides a standardized way to connect devices to peripherals, MCP provides a standardized way to connect AI models to different capabilities.

```
┌─────────────┐                  ┌──────────────────┐
│             │                  │  MCP Server      │
│   Claude    │◄────MCP─────────►│  (Capability)    │
│    (AI)     │   Protocol       │  - Tools         │
│             │                  │  - Resources     │
└─────────────┘                  │  - Prompts       │
                                 └──────────────────┘
```

### Why MCP Matters

**Before MCP:**
- Each AI tool integration required custom code
- No standard for exposing capabilities to AI models
- Difficult to share integrations across platforms
- Vendors locked into proprietary solutions

**With MCP:**
- **Standardization**: One protocol for all integrations
- **Interoperability**: Works across Claude, ChatGPT, and other AI systems
- **Ecosystem Growth**: Community can build and share MCP servers
- **Reduced Latency**: Optimized for AI-to-tool communication (<1ms for in-process)

### MCP Servers vs Clients

```
┌────────────────────────────────────────────────────────┐
│                    MCP ARCHITECTURE                     │
├────────────────────────────────────────────────────────┤
│                                                         │
│  MCP CLIENT (Host)              MCP SERVER (Provider)  │
│  ┌──────────────┐              ┌──────────────────┐   │
│  │              │    Request   │                  │   │
│  │  Claude Code │─────────────►│  Database Server │   │
│  │              │◄─────────────│  (PostgreSQL)    │   │
│  │              │    Response  │                  │   │
│  └──────────────┘              └──────────────────┘   │
│                                                         │
│  Consumes tools                Provides tools          │
│  Makes requests                Executes operations     │
│  Examples:                     Examples:               │
│  - Claude Code                 - Filesystem access     │
│  - Claude Desktop              - Database queries      │
│  - Gemini CLI                  - API integrations      │
│  - ChatGPT                     - Web search            │
│                                - GitHub operations     │
└────────────────────────────────────────────────────────┘
```

**MCP Client (Host):**
- The AI application that *uses* capabilities
- Examples: Claude Code, Claude Desktop, ChatGPT Desktop
- Sends requests to MCP servers
- Manages server lifecycle and connections

**MCP Server (Provider):**
- The service that *provides* capabilities to AI
- Exposes three primitives:
  - **Tools**: Functions the AI can invoke (e.g., `read_file`, `query_database`)
  - **Resources**: Data the AI can access (e.g., file contents, database schemas)
  - **Prompts**: Templated instructions for specific tasks
- Examples: filesystem server, database connector, GitHub integration

### How MCP Servers Extend AI Capabilities

MCP servers give AI models **superpowers** by providing:

1. **External Data Access**: Read files, query databases, fetch web pages
2. **Action Execution**: Create files, send emails, trigger builds
3. **Specialized Knowledge**: Domain-specific tools (medical, legal, financial)
4. **Integration Points**: Connect to existing services (GitHub, Slack, AWS)

**Example Flow:**
```
User: "Analyze the latest sales data from our database"
                    ↓
Claude Code → MCP Request → Database MCP Server
                               ↓
                         SELECT * FROM sales
                         WHERE date > '2025-10-01'
                               ↓
                         Results (JSON)
                               ↓
Claude Code ← MCP Response ← Database MCP Server
                    ↓
AI Analysis: "Revenue increased 23% this month..."
```

---

## 2. Local vs Remote MCP Servers

MCP servers can run either **locally** on your machine or **remotely** in the cloud. Each approach has trade-offs.

### Remote MCP Servers (Cloud-Hosted)

**Characteristics:**
- Run on cloud infrastructure (AWS, GCP, Azure)
- Accessed via network protocols (HTTP, WebSocket)
- Require authentication (API keys, OAuth)
- Billed per usage or subscription

**Diagram:**
```
┌──────────────┐        Internet         ┌─────────────────┐
│              │    (HTTPS/WSS)          │   Cloud Server  │
│ Claude Code  │◄───────────────────────►│   MCP Service   │
│  (Client)    │    API Key Auth         │   - Scalable    │
│              │                          │   - Managed     │
└──────────────┘                          │   - Pay-as-go   │
                                          └─────────────────┘
                                                   │
                                          ┌────────┴────────┐
                                          │  Example:       │
                                          │  flow-nexus     │
                                          │  ruv-swarm      │
                                          └─────────────────┘
```

**Pros:**
- No local installation required
- Professionally maintained and updated
- High availability and reliability
- Scales automatically
- Access from multiple machines

**Cons:**
- Requires internet connection
- Data leaves your machine (privacy concerns)
- API rate limits
- Subscription costs
- Network latency (50-200ms+)

**Use Cases:**
- Cloud services (AWS, GitHub, Stripe)
- Shared team capabilities
- Resource-intensive operations (ML inference)
- Public data sources (weather, news)

### Local MCP Servers (Self-Hosted)

**Characteristics:**
- Run on your local machine
- Accessed via local protocols (stdio, Unix sockets)
- No authentication needed (trust-based)
- Free to run (uses local resources)

**Diagram:**
```
┌─────────────────────────────────────────────────┐
│          YOUR MACHINE (Local)                   │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────┐          ┌────────────────┐  │
│  │              │  stdio   │  MCP Server    │  │
│  │ Claude Code  │◄────────►│  (Process)     │  │
│  │  (Client)    │  <1ms    │                │  │
│  └──────────────┘          └────────────────┘  │
│                                     │           │
│                            ┌────────┴────────┐ │
│                            │  Or: Docker      │ │
│                            │  Container       │ │
│                            │  (Isolated)      │ │
│                            └──────────────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
```

**Pros:**
- **Fast**: <1ms latency (in-process) vs 50-100ms (remote)
- **Private**: Data never leaves your machine
- **Free**: No API costs
- **Offline**: Works without internet
- **Customizable**: Full control over code and config

**Cons:**
- Requires local installation and setup
- Uses local CPU/memory
- You maintain and update it
- Limited to one machine (unless networked)
- Potential dependency conflicts

**Use Cases:**
- Filesystem operations (read/write files)
- Local databases (SQLite, PostgreSQL on localhost)
- Development tools (Git, Docker, npm)
- Private/sensitive data processing
- Low-latency requirements

### Hybrid Approach (Best of Both Worlds)

Most production setups use **both**:

```
┌──────────────┐
│ Claude Code  │
└──────┬───────┘
       │
       ├─────────────► Local MCP Servers
       │               - Filesystem (fast, private)
       │               - Local DB (fast, private)
       │               - Git (fast, private)
       │
       └─────────────► Remote MCP Servers
                       - GitHub API (cloud data)
                       - Payment APIs (cloud service)
                       - ML Models (cloud compute)
```

**MCP Manager** makes this easy by:
- Supporting both local (Docker) and remote (API) servers
- Configuring clients to use appropriate servers
- Managing lifecycle and health of local containers

---

## 3. Docker Isolation

### Why Containerize MCP Servers?

Running MCP servers in Docker containers provides **isolation**, **reproducibility**, and **safety**.

**Without Docker:**
```
┌────────────────────────────────────────┐
│      HOST MACHINE (Your System)        │
├────────────────────────────────────────┤
│                                         │
│  Node.js 18 ──► MCP Server A (needs 18)│
│                                         │
│  Node.js 20 ──► MCP Server B (needs 20)│
│                 ⚠️ CONFLICT!            │
│                                         │
│  Python 3.9 ──► MCP Server C (needs 3.9)│
│  Python 3.12 ─► MCP Server D (needs 3.12)│
│                 ⚠️ CONFLICT!            │
│                                         │
│  All share: /tmp, env vars, ports       │
└────────────────────────────────────────┘
```

**With Docker:**
```
┌─────────────────────────────────────────────────────┐
│           HOST MACHINE (Your System)                │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ Container A  │  │ Container B  │  │Container C│ │
│  ├──────────────┤  ├──────────────┤  ├───────────┤ │
│  │ Node.js 18   │  │ Node.js 20   │  │Python 3.9 │ │
│  │ MCP Server A │  │ MCP Server B │  │MCP Srvr C │ │
│  │ /tmp (own)   │  │ /tmp (own)   │  │/tmp (own) │ │
│  │ Port 3000    │  │ Port 3001    │  │Port 3002  │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
│         ↓                 ↓                 ↓        │
│     Isolated          Isolated         Isolated     │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Benefits of Docker Isolation

#### 1. **Dependency Isolation**
Each container has its own:
- Runtime version (Node.js 18 vs 20, Python 3.9 vs 3.12)
- Installed packages (npm, pip dependencies)
- System libraries (OpenSSL, libcurl)
- Configuration files

**Example:**
```yaml
# Server A needs Node.js 18
FROM node:18-alpine
RUN npm install mcp-server-sqlite@1.0.0

# Server B needs Node.js 20
FROM node:20-alpine
RUN npm install mcp-server-postgres@2.0.0
```

#### 2. **Version Control**
Lock each server to specific versions:
```yaml
# mcp_server_registry.yml
servers:
  - id: database-server
    image: postgres:15.3  # Exact version
    tag: v1.2.3           # Your custom tag
```

Even if `postgres:15.3` updates upstream, your container stays unchanged until you rebuild.

#### 3. **Reproducibility**
Containers ensure **same behavior everywhere**:

```
Developer Machine → Build Container → Push Image
                                            ↓
                                      Docker Registry
                                            ↓
         Production Server ← Pull Image ← Image

         ✅ Identical environment guaranteed
```

#### 4. **Security Sandboxing**
Containers limit what MCP servers can access:

```yaml
# Limited filesystem access (volumes)
volumes:
  - ./data:/data:ro  # Read-only

# Limited network access
network_mode: none   # No internet

# Limited resources
mem_limit: 512m      # Max 512MB RAM
cpus: 0.5            # Max 50% of one CPU
```

If a server is compromised, damage is **contained**.

#### 5. **Resource Limits**
Prevent one server from hogging resources:

```yaml
services:
  heavy-ml-server:
    mem_limit: 2g     # Max 2GB RAM
    cpus: 1.0         # Max 1 CPU core
    pids_limit: 100   # Max 100 processes
```

### Volume Mounting for Data Persistence

Containers are **ephemeral** (deleted data on restart). Use volumes to persist data.

**Without Volumes:**
```
Container Start → Create Data → Container Stop → ⚠️ Data Lost!
```

**With Volumes:**
```
┌──────────────────────────────────────────────┐
│              HOST MACHINE                     │
├──────────────────────────────────────────────┤
│                                               │
│  /home/user/mcp-data/  ←─── Persistent       │
│  ├── db/                     Storage         │
│  │   └── database.sqlite                     │
│  └── logs/                                   │
│      └── server.log                          │
│           ↕ Volume Mount                     │
│  ┌─────────────────────────┐                 │
│  │   CONTAINER             │                 │
│  ├─────────────────────────┤                 │
│  │   /data/ (mounted)      │                 │
│  │   ├── db/               │                 │
│  │   └── logs/             │                 │
│  └─────────────────────────┘                 │
│                                               │
└──────────────────────────────────────────────┘
```

**Example:**
```yaml
# docker-compose.yml
services:
  sqlite-server:
    volumes:
      - ./data/sqlite:/data        # Database files
      - ./logs:/var/log/mcp:ro     # Logs (read-only in container)
```

**Benefits:**
- Data survives container restarts
- Easy backups (just copy host directory)
- Share data between containers
- Inspect data from host machine

### Host Network for Accessibility

Containers have isolated networks by default. Use `network_mode: host` for easy access.

**Default (Bridge Network):**
```
┌────────────────────────────────────────┐
│         HOST (your machine)            │
├────────────────────────────────────────┤
│  localhost:3000 (not accessible)       │
│                                         │
│  ┌──────────────────────────────┐     │
│  │  CONTAINER                   │     │
│  │  ┌────────────────────────┐  │     │
│  │  │ MCP Server :3000       │  │     │
│  │  └────────────────────────┘  │     │
│  │         ↓                     │     │
│  │  Port Mapping Required:       │     │
│  │  -p 8080:3000                 │     │
│  └──────────────────────────────┘     │
│                                         │
│  Access via: localhost:8080            │
└────────────────────────────────────────┘
```

**Host Network:**
```
┌────────────────────────────────────────┐
│         HOST (your machine)            │
├────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────┐     │
│  │  CONTAINER (host network)    │     │
│  │  ┌────────────────────────┐  │     │
│  │  │ MCP Server :3000       │  │     │
│  │  └────────────────────────┘  │     │
│  └──────────────────────────────┘     │
│           ↓                             │
│  Access directly: localhost:3000       │
└────────────────────────────────────────┘
```

**When to use `network_mode: host`:**
- MCP server needs to bind to specific host ports
- Simplify client configuration (no port mapping)
- Performance-critical (avoid network translation overhead)

**Trade-off:** Less network isolation (container shares host network stack)

---

## 4. Build Strategies

MCP Manager supports two strategies for obtaining Docker images: **Pull from Registry** and **Build from Source**.

### Strategy Comparison Table

| Feature | Pull from Registry | Build from Source |
|---------|-------------------|-------------------|
| **Speed** | Fast (minutes) | Slow (5-30 min) |
| **Reliability** | High (pre-built) | Medium (build errors) |
| **Customization** | None | Full control |
| **Latest Code** | Only releases | Bleeding edge |
| **Disk Space** | Small (compressed) | Large (build cache) |
| **Dependencies** | Pre-bundled | Must be available |
| **Maintenance** | Low | High |

### Pull from Registry (Recommended Default)

Pull pre-built images from Docker Hub or other registries.

**Workflow:**
```
┌────────────────┐      Pull Image       ┌──────────────────┐
│  Docker Hub    │◄─────────────────────│ Your Machine     │
│  (Registry)    │                       │                  │
├────────────────┤   docker pull         ├──────────────────┤
│ ✓ mcp-sqlite   │   mcp-sqlite:latest  │ ✓ Image cached   │
│ ✓ mcp-postgres │ ──────────────────────►│ ✓ Ready to run   │
│ ✓ mcp-github   │                       │                  │
└────────────────┘                       └──────────────────┘
```

**Configuration:**
```yaml
# mcp_server_registry.yml
servers:
  - id: sqlite-server
    name: SQLite MCP Server
    image: mcp/sqlite-server    # Official image
    tag: v1.0.0                  # Specific version
    build_strategy: pull         # Pull from registry
```

**Advantages:**
- **Fast Setup**: Download in minutes vs build in 10-30 minutes
- **Pre-tested**: Official images tested by maintainers
- **Smaller Downloads**: Compressed layers (~50-200MB)
- **No Build Tools**: Don't need Docker buildkit, compilers
- **Reproducible**: Same image hash everywhere

**Disadvantages:**
- **No Customization**: Can't modify server code
- **Update Lag**: Wait for maintainers to publish new versions
- **Trust Required**: Must trust image publisher
- **Limited Versions**: Only published tags available

**When to Use:**
- Production deployments (stability matters)
- Official/well-maintained servers
- Quick setup/testing
- Limited local resources (disk, CPU)
- Standard use cases (no custom code)

### Build from Source (Advanced)

Build Docker images locally from source code.

**Workflow:**
```
┌────────────────┐    Clone Repo        ┌──────────────────┐
│  GitHub        │◄─────────────────────│ Your Machine     │
│  (Source)      │                       │                  │
├────────────────┤   git clone          ├──────────────────┤
│ Dockerfile     │ ──────────────────────►│ 1. Download code │
│ package.json   │                       │ 2. Run `docker   │
│ src/           │                       │    build`        │
│ ...            │                       │ 3. ✓ Image built │
└────────────────┘                       └──────────────────┘
                                                 │
                                         ┌───────┴────────┐
                                         │ Build Process: │
                                         │ - npm install  │
                                         │ - tsc compile  │
                                         │ - tests        │
                                         │ - package      │
                                         └────────────────┘
```

**Configuration:**
```yaml
# mcp_server_registry.yml
servers:
  - id: custom-sqlite-server
    name: Custom SQLite MCP Server
    build_strategy: build           # Build from source
    dockerfile_path: ./Dockerfile   # Custom Dockerfile
    build_context: ./src            # Build context
    build_args:
      NODE_VERSION: "20"            # Build arguments
      FEATURES: "encryption,wal"
```

**Advantages:**
- **Full Customization**: Modify any code before building
- **Latest Features**: Use unreleased code from main branch
- **Custom Configurations**: Add environment-specific tweaks
- **Debug Builds**: Add logging, profiling, debugging tools
- **Private Code**: Build from internal repositories

**Disadvantages:**
- **Slow**: 5-30 minutes per build (depends on complexity)
- **Build Failures**: Compilation errors, missing dependencies
- **Large Disk Usage**: Build cache can be 1-5GB per image
- **Maintenance Burden**: Update Dockerfiles when deps change
- **Requires Expertise**: Need Docker + language knowledge

**When to Use:**
- Development/testing of MCP servers
- Need unreleased features/fixes
- Custom modifications required
- Private/proprietary servers
- Contributing to MCP server projects

### Hybrid Strategy (Best Practice)

Use **pull** for most servers, **build** only when needed:

```yaml
# mcp_server_registry.yml
servers:
  # Production servers: PULL
  - id: sqlite-official
    build_strategy: pull
    image: mcp/sqlite-server
    tag: v1.0.0

  - id: github-official
    build_strategy: pull
    image: mcp/github-server
    tag: v2.3.1

  # Development server: BUILD
  - id: custom-analytics
    build_strategy: build
    dockerfile_path: ./custom/Dockerfile
    build_context: ./custom/src
```

**MCP Manager's Role:**
- Detects strategy from registry
- Pulls images or builds from source
- Caches results to avoid rebuilds
- Validates images before running
- Provides fallback on build failure

---

## 5. Configuration Management

MCP Manager handles four types of configuration:

### Configuration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 CONFIGURATION LAYERS                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. SERVER REGISTRY (mcp_server_registry.yml)           │
│     ┌────────────────────────────────────────┐          │
│     │ - Server definitions                   │          │
│     │ - Build strategies                     │          │
│     │ - Docker configs                       │          │
│     │ - Port mappings                        │          │
│     └────────────────────────────────────────┘          │
│                        ↓                                 │
│  2. ENVIRONMENT (.env)                                   │
│     ┌────────────────────────────────────────┐          │
│     │ - API keys (GITHUB_TOKEN)              │          │
│     │ - Secrets (DATABASE_PASSWORD)          │          │
│     │ - Global settings (LOG_LEVEL)          │          │
│     └────────────────────────────────────────┘          │
│                        ↓                                 │
│  3. CLIENT CONFIGS (generated)                           │
│     ┌────────────────────────────────────────┐          │
│     │ - Claude Code: .mcp.json               │          │
│     │ - Claude Desktop: claude_desktop_config│          │
│     │ - Gemini CLI: gemini_config.json       │          │
│     └────────────────────────────────────────┘          │
│                        ↓                                 │
│  4. RUNTIME STATE (.mcp-manager/)                        │
│     ┌────────────────────────────────────────┐          │
│     │ - Container IDs                        │          │
│     │ - Health status                        │          │
│     │ - Version tracking                     │          │
│     │ - Metrics/logs                         │          │
│     └────────────────────────────────────────┘          │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 1. Server Registry (mcp_server_registry.yml)

**Purpose:** Define all available MCP servers (local and remote).

**Example:**
```yaml
# mcp_server_registry.yml
version: "1.0"

servers:
  # Local server (Docker)
  - id: sqlite-server
    name: SQLite MCP Server
    description: Provides access to SQLite databases
    type: local
    build_strategy: pull
    image: mcp/sqlite-server
    tag: v1.0.0
    transport: stdio
    port: 3000
    volumes:
      - ./data/sqlite:/data
    environment:
      - LOG_LEVEL=${LOG_LEVEL}
      - SQLITE_DB_PATH=/data/main.db
    health_check:
      command: ["sqlite3", "/data/main.db", "SELECT 1"]
      interval: 30s
      timeout: 5s
      retries: 3

  # Remote server (Cloud)
  - id: flow-nexus
    name: Flow Nexus Cloud
    description: Cloud orchestration platform
    type: remote
    api_url: https://api.flow-nexus.ruv.io
    auth:
      type: token
      env_var: FLOW_NEXUS_TOKEN
    capabilities:
      - neural_training
      - sandbox_execution
      - template_deployment
```

**Key Fields:**
- `id`: Unique identifier
- `type`: `local` (Docker) or `remote` (API)
- `build_strategy`: `pull` or `build`
- `image/tag`: Docker image reference
- `volumes`: Persistent data mounts
- `environment`: Container environment variables

### 2. Environment Variables (.env)

**Purpose:** Store secrets and global settings (never commit to Git).

**Example:**
```bash
# .env (keep secret!)

# API Keys
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
FLOW_NEXUS_TOKEN=fn_xxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxx

# Database Credentials
DATABASE_PASSWORD=super_secret_pwd
POSTGRES_USER=admin

# Global Settings
LOG_LEVEL=info
MCP_MANAGER_DATA_DIR=/home/user/mcp-data
DOCKER_NETWORK=mcp-network

# Feature Flags
ENABLE_METRICS=true
ENABLE_AUTO_UPDATES=false
```

**Security Best Practices:**
```bash
# .gitignore
.env          # ALWAYS ignore
.env.local
*.secret

# .env.example (commit this)
# Template for other developers
GITHUB_TOKEN=your_token_here
DATABASE_PASSWORD=your_password
LOG_LEVEL=info
```

**Usage in Registry:**
```yaml
# Reference .env variables
servers:
  - id: github-server
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}  # Injected from .env
      - LOG_LEVEL=${LOG_LEVEL}
```

### 3. Client Configurations (Generated)

MCP Manager generates configuration files for different AI clients.

#### Claude Code (.mcp.json)

**Format:**
```json
{
  "mcpServers": {
    "sqlite-server": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-sqlite-server", "mcp-server-sqlite"],
      "type": "stdio"
    },
    "flow-nexus": {
      "command": "npx",
      "args": ["flow-nexus@latest", "mcp", "start"],
      "type": "stdio",
      "env": {
        "FLOW_NEXUS_TOKEN": "fn_xxxxxxxxxxxx"
      }
    }
  }
}
```

#### Claude Desktop (claude_desktop_config.json)

**Location:** `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)

**Format:**
```json
{
  "mcpServers": {
    "sqlite": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-sqlite-server", "/usr/local/bin/mcp-server-sqlite"]
    }
  }
}
```

#### Gemini CLI (gemini_config.json)

**Format:**
```json
{
  "mcp": {
    "servers": [
      {
        "id": "sqlite-server",
        "transport": "stdio",
        "command": "docker exec -i mcp-sqlite-server mcp-server-sqlite"
      }
    ]
  }
}
```

### Config Snippets vs Complete Files

**MCP Manager Strategy:**

```
┌──────────────────────────────────────────────┐
│        CONFIGURATION GENERATION               │
├──────────────────────────────────────────────┤
│                                               │
│  Option 1: SNIPPETS (Safe)                   │
│  ┌────────────────────────────────┐          │
│  │ Generate partial config:       │          │
│  │                                 │          │
│  │ # Add this to .mcp.json:       │          │
│  │ "sqlite-server": {             │          │
│  │   "command": "docker",         │          │
│  │   ...                           │          │
│  │ }                               │          │
│  │                                 │          │
│  │ User manually merges ────►      │          │
│  └────────────────────────────────┘          │
│                                               │
│  Option 2: COMPLETE FILE (Automated)          │
│  ┌────────────────────────────────┐          │
│  │ 1. Read existing .mcp.json     │          │
│  │ 2. Merge new server config     │          │
│  │ 3. Backup old file             │          │
│  │ 4. Write complete config       │          │
│  │                                 │          │
│  │ Fully automated ────►           │          │
│  └────────────────────────────────┘          │
│                                               │
└──────────────────────────────────────────────┘
```

**Snippet Approach (Manual Merge):**
```bash
# Generate snippet
$ mcp-manager config generate sqlite-server --format snippet

Output:
===========================================
Add this to your .mcp.json:
===========================================
"sqlite-server": {
  "command": "docker",
  "args": ["exec", "-i", "mcp-sqlite-server", "..."]
}
===========================================
```

**Complete File Approach (Automatic):**
```bash
# Generate and merge automatically
$ mcp-manager config generate --client claude-code --merge

✓ Read existing .mcp.json
✓ Backed up to .mcp.json.backup
✓ Added sqlite-server configuration
✓ Wrote updated .mcp.json
```

**Trade-offs:**

| Approach | Pros | Cons |
|----------|------|------|
| **Snippets** | Safe (no overwrites)<br>User controls merge<br>Review before applying | Manual work<br>Error-prone (copy/paste)<br>Slower |
| **Complete File** | Fully automated<br>No manual work<br>Consistent format | Risk of overwrites<br>Requires backup<br>Less user control |

**MCP Manager Recommendation:** Support both, default to snippets, offer `--merge` flag for automation.

### 4. Runtime State Tracking

**Purpose:** Track running containers, health, versions.

**State Directory Structure:**
```
.mcp-manager/
├── state/
│   ├── containers.json      # Running container info
│   ├── versions.json         # Installed versions
│   └── health.json           # Health check results
├── logs/
│   ├── sqlite-server.log
│   └── postgres-server.log
└── metrics/
    ├── performance.json
    └── usage.json
```

**containers.json Example:**
```json
{
  "containers": [
    {
      "id": "abc123def456",
      "server_id": "sqlite-server",
      "image": "mcp/sqlite-server:v1.0.0",
      "status": "running",
      "started_at": "2025-10-04T10:30:00Z",
      "ports": {
        "3000/tcp": "3000"
      },
      "health": "healthy",
      "last_health_check": "2025-10-04T11:00:00Z"
    }
  ]
}
```

**health.json Example:**
```json
{
  "checks": [
    {
      "server_id": "sqlite-server",
      "timestamp": "2025-10-04T11:00:00Z",
      "status": "healthy",
      "response_time_ms": 12,
      "details": {
        "database_accessible": true,
        "disk_space_mb": 2048,
        "memory_usage_mb": 128
      }
    }
  ]
}
```

---

## 6. State Tracking

MCP Manager maintains **stateful awareness** of all managed servers.

### What We Track

```
┌───────────────────────────────────────────────────────┐
│                  STATE TRACKING                        │
├───────────────────────────────────────────────────────┤
│                                                        │
│  1. CONTAINER LIFECYCLE                                │
│     ┌────────────────────────────────────┐            │
│     │ - Container ID                     │            │
│     │ - Status: created/running/stopped  │            │
│     │ - Start/stop timestamps            │            │
│     │ - Restart count                    │            │
│     │ - Exit codes (if crashed)          │            │
│     └────────────────────────────────────┘            │
│                                                        │
│  2. VERSION TRACKING                                   │
│     ┌────────────────────────────────────┐            │
│     │ - Image version (tag)              │            │
│     │ - Build date                       │            │
│     │ - Source commit (if built)         │            │
│     │ - Upgrade history                  │            │
│     └────────────────────────────────────┘            │
│                                                        │
│  3. HEALTH MONITORING                                  │
│     ┌────────────────────────────────────┐            │
│     │ - Last health check                │            │
│     │ - Response time                    │            │
│     │ - Error count                      │            │
│     │ - Uptime percentage                │            │
│     └────────────────────────────────────┘            │
│                                                        │
│  4. RESOURCE USAGE                                     │
│     ┌────────────────────────────────────┐            │
│     │ - CPU usage (%)                    │            │
│     │ - Memory usage (MB)                │            │
│     │ - Disk usage (MB)                  │            │
│     │ - Network I/O (bytes)              │            │
│     └────────────────────────────────────┘            │
│                                                        │
└───────────────────────────────────────────────────────┘
```

### Container Lifecycle Management

**State Transitions:**
```
┌─────────────────────────────────────────────────────┐
│          CONTAINER LIFECYCLE STATES                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│   [Created] ──start──► [Running] ──stop──► [Stopped]│
│       │                    │                   │     │
│       │                    │                   │     │
│       │                 [Paused]            [Exited] │
│       │                    │                   │     │
│       │                    │                   │     │
│       └────remove──────────┴───────remove──────┘     │
│                                                      │
│   Health States:                                     │
│   - starting    (initializing)                       │
│   - healthy     (all checks pass)                    │
│   - unhealthy   (checks failing)                     │
│   - none        (no health check)                    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Example State Tracking:**
```bash
# Check container state
$ mcp-manager status sqlite-server

Server: sqlite-server
  Status: running
  Container ID: abc123def456
  Uptime: 3 days, 4 hours
  Health: healthy (last check: 30s ago)
  Version: mcp/sqlite-server:v1.0.0
  Resources:
    CPU: 2.3%
    Memory: 128 MB / 512 MB (25%)
    Disk: 45 MB
```

**Automated Actions:**
```yaml
# Lifecycle policies
lifecycle:
  restart_policy: on-failure
  max_restarts: 3
  health_check_interval: 30s
  unhealthy_threshold: 3    # Mark unhealthy after 3 failures
  auto_restart: true         # Auto-restart if unhealthy
```

### Version Tracking

**Why Track Versions?**
- Know which server version is running
- Detect outdated images
- Rollback to previous versions
- Audit trail for changes

**Version Data Structure:**
```json
{
  "servers": {
    "sqlite-server": {
      "current_version": "v1.0.0",
      "image_id": "sha256:abc123...",
      "built_at": "2025-10-01T12:00:00Z",
      "source_commit": "a1b2c3d",
      "version_history": [
        {
          "version": "v1.0.0",
          "installed_at": "2025-10-01T15:30:00Z",
          "source": "docker_hub"
        },
        {
          "version": "v0.9.5",
          "installed_at": "2025-09-15T10:00:00Z",
          "removed_at": "2025-10-01T15:30:00Z"
        }
      ]
    }
  }
}
```

**Version Commands:**
```bash
# Check for updates
$ mcp-manager update check

Available updates:
  sqlite-server: v1.0.0 → v1.1.0 (new features)
  postgres-server: v2.3.1 → v2.4.0 (security fixes)

# Upgrade server
$ mcp-manager update sqlite-server

✓ Pulled mcp/sqlite-server:v1.1.0
✓ Stopped old container
✓ Started new container (v1.1.0)
✓ Health check passed

# Rollback if needed
$ mcp-manager rollback sqlite-server

✓ Rolled back to v1.0.0
```

### Health Monitoring

**Health Check Types:**

1. **Container Health** (Docker built-in)
   ```yaml
   health_check:
     test: ["CMD", "sqlite3", "/data/main.db", "SELECT 1"]
     interval: 30s
     timeout: 5s
     retries: 3
     start_period: 10s
   ```

2. **Application Health** (MCP Manager custom)
   ```bash
   # HTTP endpoint check
   curl http://localhost:3000/health

   # MCP protocol check
   echo '{"jsonrpc":"2.0","method":"ping","id":1}' | \
     docker exec -i mcp-sqlite-server mcp-server-sqlite
   ```

3. **Resource Health** (thresholds)
   ```yaml
   resource_limits:
     cpu_alert_threshold: 80%    # Warn if CPU > 80%
     memory_alert_threshold: 90% # Warn if memory > 90%
     disk_alert_threshold: 95%   # Warn if disk > 95%
   ```

**Health Status Flow:**
```
Every 30 seconds:
  ├─► Run health check command
  ├─► Record response time
  ├─► Update health status
  ├─► If 3 consecutive failures:
  │     ├─► Mark as unhealthy
  │     └─► Trigger alert/restart
  └─► Store metrics
```

### Persistence via Volumes

**Persistent State Storage:**
```
┌─────────────────────────────────────────────────┐
│         HOST FILESYSTEM (Persistent)            │
├─────────────────────────────────────────────────┤
│                                                  │
│  .mcp-manager/                                  │
│  ├── state/                                     │
│  │   ├── containers.json    ← Always persisted │
│  │   ├── versions.json      ← Always persisted │
│  │   └── health.json        ← Always persisted │
│  │                                               │
│  ├── volumes/                                   │
│  │   ├── sqlite-server/                         │
│  │   │   └── data/                              │
│  │   │       └── main.db    ← Server data      │
│  │   │                                           │
│  │   └── postgres-server/                       │
│  │       └── data/                              │
│  │           └── pgdata/    ← Server data      │
│  │                                               │
│  └── logs/                                      │
│      ├── sqlite-server.log  ← Rolling logs     │
│      └── manager.log        ← Manager logs     │
│                                                  │
└─────────────────────────────────────────────────┘
```

**Backup Strategy:**
```bash
# Automatic backups before updates
$ mcp-manager update sqlite-server

⏳ Creating backup...
  ✓ Backed up state to .mcp-manager/backups/2025-10-04/
  ✓ Backed up volumes to .mcp-manager/backups/2025-10-04/
⏳ Updating server...
  ✓ Updated to v1.1.0

# Manual backup
$ mcp-manager backup create --all

✓ Backed up all servers to .mcp-manager/backups/2025-10-04/
```

---

## 7. Testing Philosophy

MCP Manager follows **Test-Driven Development (TDD)** with a focus on **fast feedback** and **real-world validation**.

### Testing Pyramid

```
┌─────────────────────────────────────────────────┐
│            TESTING PYRAMID                       │
├─────────────────────────────────────────────────┤
│                                                  │
│                    /\                            │
│                   /  \                           │
│                  /    \    E2E Tests             │
│                 / (Few)\   - Full workflows      │
│                /────────\  - Real Docker         │
│               /          \ - Slow (minutes)      │
│              /            \                      │
│             / Integration  \                     │
│            /   Tests (Some) \                    │
│           /──────────────────\                   │
│          / - Docker builds    \                  │
│         /  - Health checks     \                 │
│        /   - Medium (seconds)   \                │
│       /─────────────────────────\                │
│      /                            \               │
│     /        Unit Tests            \              │
│    /         (Many)                 \             │
│   /────────────────────────────────\             │
│  / - Core logic                     \            │
│ /  - Config parsing                  \           │
│/   - Fast (milliseconds)              \          │
│────────────────────────────────────────          │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Unit Tests (Fast, Isolated, Core Logic)

**Goal:** Test individual functions in isolation, no external dependencies.

**Characteristics:**
- **Fast**: <100ms per test, thousands/second
- **Isolated**: No Docker, no network, no filesystem (mocked)
- **Deterministic**: Same input = same output, always
- **Focused**: One function/module per test

**Example (using ShellSpec):**
```bash
# spec/unit/config_parser_spec.sh

Describe 'parse_server_registry()'
  It 'parses valid YAML registry'
    When call parse_server_registry "fixtures/valid_registry.yml"
    The output should include "sqlite-server"
    The status should be success
  End

  It 'rejects invalid YAML'
    When call parse_server_registry "fixtures/invalid.yml"
    The status should be failure
    The stderr should include "YAML parse error"
  End

  It 'validates required fields'
    When call parse_server_registry "fixtures/missing_id.yml"
    The status should be failure
    The stderr should include "Missing required field: id"
  End
End
```

**What to Unit Test:**
- Configuration parsing (YAML, JSON, .env)
- State file reading/writing
- Version comparison logic
- Health status calculation
- Command argument building
- Error message formatting

**What NOT to Unit Test:**
- Docker commands (integration test)
- Network requests (integration test)
- File I/O (mock or integration test)

### Integration Tests (Real Docker, Health Validation)

**Goal:** Test interactions with real Docker daemon and containers.

**Characteristics:**
- **Realistic**: Uses actual Docker builds/runs
- **Slower**: 5-60 seconds per test
- **Stateful**: May leave containers/images (cleanup required)
- **Environment-dependent**: Requires Docker installed

**Example (using ShellSpec):**
```bash
# spec/integration/docker_build_spec.sh

Describe 'build_server_image()'
  # Setup: Create test Dockerfile
  BeforeEach 'setup_test_dockerfile'
  AfterEach 'cleanup_test_containers'

  It 'builds image from Dockerfile'
    When call build_server_image "test-server" "test/Dockerfile"
    The status should be success
    The output should include "Successfully built"
  End

  It 'runs built container'
    # Build image first
    build_server_image "test-server" "test/Dockerfile"

    # Run container
    When call run_server_container "test-server"
    The status should be success

    # Verify running
    docker ps --filter "name=test-server" | grep "test-server"
  End

  It 'passes health check'
    # Build and run
    build_server_image "test-server" "test/Dockerfile"
    run_server_container "test-server"

    # Wait for healthy status
    When call wait_for_health "test-server" 30
    The status should be success
    The output should include "healthy"
  End
End

# Helper functions
setup_test_dockerfile() {
  mkdir -p test/
  cat > test/Dockerfile <<EOF
FROM alpine:3.18
RUN apk add --no-cache sqlite
HEALTHCHECK CMD sqlite3 -version || exit 1
CMD ["sleep", "infinity"]
EOF
}

cleanup_test_containers() {
  docker rm -f test-server 2>/dev/null || true
  docker rmi test-server 2>/dev/null || true
  rm -rf test/
}
```

**What to Integration Test:**
- Docker image builds (pull/build)
- Container lifecycle (start/stop/restart)
- Health checks (real commands)
- Volume mounts (data persistence)
- Network connectivity
- Multi-container scenarios

### TDD Workflow with ShellSpec

**Red-Green-Refactor Cycle:**

```
┌──────────────────────────────────────────────────┐
│              TDD WORKFLOW                         │
├──────────────────────────────────────────────────┤
│                                                   │
│  1. RED (Write failing test)                     │
│     ┌────────────────────────────────┐           │
│     │ It 'builds Docker image'       │           │
│     │   When call build_image        │           │
│     │   The status should be success │           │
│     │ End                             │           │
│     └────────────────────────────────┘           │
│              ↓                                    │
│     $ shellspec spec/                            │
│     ❌ FAIL: build_image: command not found      │
│                                                   │
│  2. GREEN (Write minimal code to pass)           │
│     ┌────────────────────────────────┐           │
│     │ build_image() {                │           │
│     │   docker build -t "$1" .       │           │
│     │ }                               │           │
│     └────────────────────────────────┘           │
│              ↓                                    │
│     $ shellspec spec/                            │
│     ✅ PASS: builds Docker image                 │
│                                                   │
│  3. REFACTOR (Improve code quality)              │
│     ┌────────────────────────────────┐           │
│     │ build_image() {                │           │
│     │   local name="$1"              │           │
│     │   local context="${2:-.}"      │           │
│     │   docker build -t "$name"      │           │
│     │     --progress=plain "$context"│           │
│     │ }                               │           │
│     └────────────────────────────────┘           │
│              ↓                                    │
│     $ shellspec spec/                            │
│     ✅ PASS: builds Docker image                 │
│                                                   │
│  4. REPEAT for next feature                      │
│                                                   │
└──────────────────────────────────────────────────┘
```

**Example Session:**
```bash
# 1. Write test first
$ vim spec/unit/version_spec.sh
Describe 'compare_versions()'
  It 'returns true if v1 < v2'
    When call compare_versions "1.0.0" "2.0.0"
    The status should be success
  End
End

# 2. Run test (should fail)
$ shellspec spec/unit/version_spec.sh
F

Failures:
  1) compare_versions() returns true if v1 < v2
     Expected success but failed
     # spec/unit/version_spec.sh:3

Finished in 0.05 seconds
1 example, 1 failure

# 3. Implement function
$ vim src/version.sh
compare_versions() {
  local v1="$1"
  local v2="$2"
  # Simple string comparison (oversimplified)
  [ "$v1" \< "$v2" ]
}

# 4. Run test (should pass)
$ shellspec spec/unit/version_spec.sh
.

Finished in 0.03 seconds
1 example, 0 failures

# 5. Add more edge cases
$ vim spec/unit/version_spec.sh
Describe 'compare_versions()'
  It 'handles patch versions'
    When call compare_versions "1.0.1" "1.0.2"
    The status should be success
  End

  It 'handles major versions'
    When call compare_versions "1.9.9" "2.0.0"
    The status should be success
  End
End

# 6. Run all tests, refactor as needed
$ shellspec spec/
```

### Test Organization

**Directory Structure:**
```
mcp-manager/
├── spec/
│   ├── unit/
│   │   ├── config_parser_spec.sh
│   │   ├── version_spec.sh
│   │   ├── state_tracker_spec.sh
│   │   └── health_checker_spec.sh
│   │
│   ├── integration/
│   │   ├── docker_build_spec.sh
│   │   ├── container_lifecycle_spec.sh
│   │   ├── volume_mount_spec.sh
│   │   └── health_check_spec.sh
│   │
│   ├── fixtures/
│   │   ├── valid_registry.yml
│   │   ├── invalid_registry.yml
│   │   └── test_dockerfile/
│   │
│   └── spec_helper.sh  # Shared test utilities
│
└── src/
    ├── config_parser.sh
    ├── version.sh
    ├── state_tracker.sh
    └── ...
```

**Running Tests:**
```bash
# Run all tests
$ shellspec

# Run only unit tests (fast)
$ shellspec spec/unit/

# Run only integration tests (slow)
$ shellspec spec/integration/

# Run specific test file
$ shellspec spec/unit/config_parser_spec.sh

# Run with coverage
$ shellspec --format documentation --coverage

# Run in CI (fail fast)
$ shellspec --fail-fast --format tap
```

### Benefits of TDD Approach

**For MCP Manager:**
1. **Confidence in Core Logic**: Unit tests ensure config parsing, version comparison, state tracking work correctly
2. **Real-World Validation**: Integration tests ensure Docker builds, containers, health checks work end-to-end
3. **Fast Development**: Red-green-refactor cycle keeps momentum
4. **Regression Prevention**: Tests catch breaks when refactoring
5. **Documentation**: Tests serve as usage examples
6. **CI/CD Ready**: Automated tests ensure quality before release

**Test Coverage Goals:**
- **Unit Tests**: 80%+ coverage of core logic
- **Integration Tests**: 100% coverage of Docker operations
- **E2E Tests**: Critical user workflows (install, start, health check)

---

## Summary

This document covered the seven core concepts of MCP Manager:

1. **MCP**: Open protocol for AI-to-tool communication, like "USB-C for AI"
2. **Local vs Remote**: Trade-offs between fast/private (local) and scalable/managed (remote)
3. **Docker Isolation**: Containers provide dependency isolation, version control, security sandboxing
4. **Build Strategies**: Pull pre-built images (fast) vs build from source (customizable)
5. **Configuration Management**: Registry definitions, environment secrets, client configs, runtime state
6. **State Tracking**: Container lifecycle, version history, health monitoring, resource usage
7. **Testing Philosophy**: TDD with fast unit tests and realistic integration tests using ShellSpec

**Next Steps:**
- Read `architecture.md` for system design details
- Read `user-guide.md` for practical usage examples
- Explore `api-reference.md` for command documentation

---

**Document Version:** 1.0.0
**Last Updated:** 2025-10-04
**Maintained by:** MCP Manager Team
