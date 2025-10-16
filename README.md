# MCP Manager

> A shell-based tool for managing Model Context Protocol (MCP) servers with Docker

MCP Manager simplifies the deployment and management of MCP servers through Docker containerization. It provides a unified interface for setting up, configuring, and maintaining multiple MCP servers across different AI development environments.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [Registry Reference](#registry-reference)
- [Development](#development)
- [License](#license)

---

## Features

- 🚀 **Easy Setup** - Pull pre-built images or build from source repositories
- 🐳 **Docker-Based** - Isolated, reproducible server environments
- 🔧 **Multi-Platform** - Automatic platform detection (amd64/arm64)
- 📝 **Config Generation** - Generate configs for Claude Code, Claude Desktop, Gemini CLI
- 🔐 **Environment Management** - Centralized `.env` file for secrets
- ✅ **Health Checking** - Verify server readiness with MCP protocol tests
- 🧪 **Well-Tested** - 237+ unit tests with ShellSpec

---

## Quick Start

### Prerequisites

- **Docker** (20.10+) - Container runtime
- **yq** (v4+) - YAML processor
- **jq** (1.6+) - JSON processor
- **git** - For building from source
- **jinja2-cli** - Template rendering

**Installation:**
```bash
# macOS
brew install docker yq jq git
pip install jinja2-cli

# Debian/Ubuntu
apt-get install docker.io jq git
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
pip install jinja2-cli
```

### Installation

```bash
# Clone the repository
git clone https://github.com/Govinda-Fichtner/mcp-manager.git
cd mcp-manager

# Make script executable
chmod +x mcp_manager.sh

# Check dependencies
./mcp_manager.sh version
```

### Basic Commands

```bash
# List available MCP servers
./mcp_manager.sh list

# Setup a server (pulls or builds Docker image)
./mcp_manager.sh setup github

# View server information
./mcp_manager.sh info github

# Check server health
./mcp_manager.sh health github

# Generate client configuration
./mcp_manager.sh config github --format claude-code
```

---

## Usage Guide

### Available Commands

#### `list`
Display all MCP servers available in the registry with categories and descriptions.

```bash
./mcp_manager.sh list
```

#### `setup <server>`
Set up an MCP server by pulling a pre-built Docker image or building from source repository.

```bash
# Pull from Docker registry (e.g., GitHub server)
./mcp_manager.sh setup github

# Build from Git repository (e.g., Obsidian server)
./mcp_manager.sh setup obsidian
```

#### `info <server>`
Display detailed information about a specific server including source, environment variables, and Docker configuration.

```bash
./mcp_manager.sh info github
```

#### `health <server>`
Verify server health by checking Docker image existence and MCP protocol compliance.

```bash
./mcp_manager.sh health github
```

#### `config <server>`
Generate client configuration for Claude Code, Claude Desktop, or Gemini CLI.

```bash
# Full configuration file
./mcp_manager.sh config github --format claude-code --full

# Snippet for manual copy-paste
./mcp_manager.sh config github --format claude-code --snippet

# Single-line JSON for 'claude mcp add-json' command
./mcp_manager.sh config github --format claude-code --add-json
```

**Supported formats:**
- `claude-code` - Claude Code JSON format
- `claude-desktop` - Claude Desktop JSON format
- `gemini-cli` - Gemini CLI YAML format

#### `version`
Display MCP Manager version and check dependency status.

```bash
./mcp_manager.sh version
```

### Environment Configuration

Create a `.env` file to store credentials and paths:

```bash
# Copy template
cp .env.example .env

# Edit with your credentials
nano .env
```

**Example `.env` file:**
```bash
# GitHub MCP Server
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here

# Obsidian MCP Server
OBSIDIAN_API_KEY=your_api_key_here
OBSIDIAN_BASE_URL=https://127.0.0.1:27124
OBSIDIAN_VAULT_NAME=MyVault

# Filesystem MCP Server
ALLOWED_DIRECTORIES=/home/user/projects,/home/user/documents

# Debugger MCP Servers
DEBUGGER_WORKSPACE=/home/user/code
```

### Adding a Custom Server

1. **Update Registry** (`mcp_server_registry.yml`):

```yaml
servers:
  my-server:
    name: "My Custom MCP Server"
    description: "What this server does"
    category: "custom"
    server_type: "api_based"  # or "mount_based", "standalone"

    source:
      type: "registry"  # or "repository"
      image: "ghcr.io/org/my-server:latest"

    environment_variables:
      - "MY_API_KEY"
      - "MY_CONFIG_PATH"

    docker:
      network_mode: "host"

    startup_timeout: 10
```

2. **Add Credentials** (`.env`):
```bash
MY_API_KEY=your_key_here
MY_CONFIG_PATH=/path/to/config
```

3. **Test**:
```bash
./mcp_manager.sh info my-server
./mcp_manager.sh setup my-server
./mcp_manager.sh health my-server
```

### Troubleshooting

#### Missing Dependencies
```bash
# Check which dependencies are missing
./mcp_manager.sh version

# Install missing tools (see Prerequisites)
```

#### Invalid YAML Syntax
Ensure you're using yq v4+ (Go version), not the old Python version:
```bash
yq --version  # Should show v4.x.x
```

#### Failed to Pull Image
```bash
# Check Docker daemon
docker info

# Verify registry URL in mcp_server_registry.yml
./mcp_manager.sh info <server>

# Test network connectivity
curl -I https://ghcr.io
```

#### Failed to Build from Source
```bash
# Verify Git is installed
git --version

# Check repository is accessible
git ls-remote <repository-url>

# Check Docker build logs
docker images | grep mcp
```

#### Server Not Starting
```bash
# Check Docker logs
docker ps -a | grep <server-name>
docker logs <container-id>

# Verify environment variables are set
cat .env | grep <VAR_NAME>

# Test health check manually
./mcp_manager.sh health <server> -v
```

#### Permission Denied
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Or use sudo
sudo ./mcp_manager.sh setup <server>
```

---

## Registry Reference

### Registry Schema

The `mcp_server_registry.yml` file defines all available MCP servers using a structured YAML schema.

#### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | string | Human-readable server name | "GitHub MCP Server" |
| `description` | string | What the server does | "GitHub API integration" |
| `category` | string | Server category | "development", "knowledge" |
| `server_type` | enum | Server classification | "api_based", "mount_based", "standalone" |
| `source.type` | enum | How to obtain server | "registry" or "repository" |

#### Source Configuration

**Registry Type** (pull pre-built image):
```yaml
source:
  type: "registry"
  image: "ghcr.io/org/server:latest"
```

**Repository Type** (build from source):
```yaml
source:
  type: "repository"
  repository: "https://github.com/org/repo.git"
  image: "local/server:latest"
  dockerfile: "Dockerfile"  # optional
  build_context: "."  # optional
```

#### Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `environment_variables` | string[] | Required env vars | ["API_KEY", "BASE_URL"] |
| `volumes` | string[] | Volume mount specs | ["VAULT:/vault:ro"] |
| `docker.network_mode` | string | Docker network mode | "host", "bridge" |
| `docker.cmd` | string[] | Container command | ["node", "index.js"] |
| `startup_timeout` | number | Startup timeout (seconds) | 10, 30 |

### Server Types

#### `api_based`
Requires API credentials but no local file access.

**Example:** GitHub, Figma, Heroku servers

```yaml
github:
  server_type: "api_based"
  environment_variables:
    - "GITHUB_PERSONAL_ACCESS_TOKEN"
  docker:
    network_mode: "host"
```

#### `mount_based`
Requires volume mounts for local file/directory access.

**Example:** Filesystem, Debugger, Obsidian servers

```yaml
filesystem:
  server_type: "mount_based"
  environment_variables:
    - "ALLOWED_DIRECTORIES"
  volumes:
    - "/project:/project:ro"
```

#### `standalone`
Self-contained with no external dependencies.

**Example:** Memory service, basic utilities

```yaml
memory-service:
  server_type: "standalone"
  # No environment variables or volumes required
```

### Complete Examples

#### Example 1: GitHub (Registry Pull)

```yaml
github:
  name: "GitHub MCP Server"
  description: "GitHub repository management, issues, pull requests, and code search"
  category: "development"
  server_type: "api_based"

  source:
    type: "registry"
    image: "ghcr.io/github/github-mcp-server:latest"

  environment_variables:
    - "GITHUB_PERSONAL_ACCESS_TOKEN"

  docker:
    network_mode: "host"

  startup_timeout: 10
```

#### Example 2: Obsidian (Repository Build)

```yaml
obsidian:
  name: "Obsidian MCP Server"
  description: "Comprehensive Obsidian vault management"
  category: "knowledge"
  server_type: "api_based"

  source:
    type: "repository"
    repository: "https://github.com/cyanheads/obsidian-mcp-server.git"
    image: "local/obsidian-mcp-server:latest"
    dockerfile: "support/docker/Dockerfile.obsidian"
    build_context: "."

  environment_variables:
    - "OBSIDIAN_API_KEY"
    - "OBSIDIAN_BASE_URL"
    - "OBSIDIAN_VAULT_NAME"

  docker:
    network_mode: "host"

  startup_timeout: 20
```

#### Example 3: Debugger (Multi-Language)

```yaml
debugger-python:
  name: "DAP MCP Server (Python)"
  description: "Debug Adapter Protocol server for Python debugging"
  category: "development"
  server_type: "mount_based"

  source:
    type: "repository"
    repository: "https://github.com/Govinda-Fichtner/debugger-mcp.git"
    image: "mcp-debugger-python:latest"
    dockerfile: "Dockerfile.python"
    build_context: "."

  environment_variables:
    - "DEBUGGER_WORKSPACE"

  volumes:
    - "DEBUGGER_WORKSPACE:/workspace"

  docker:
    network_mode: "host"
    cmd: ["debugger_mcp", "serve"]

  startup_timeout: 15
```

---

## Development

### Project Structure

```
mcp-manager/
├── mcp_manager.sh           # Main script (~1,400 lines)
├── mcp_server_registry.yml  # Server definitions
├── .env.example             # Environment template
├── support/
│   ├── docker/              # Custom Dockerfiles
│   └── templates/           # Jinja2 config templates
└── spec/
    ├── unit/                # Unit tests (237 examples)
    └── fixtures/            # Test data
```

### Architecture

**Design Principles:**
- **Single script** - All functionality in `mcp_manager.sh` for simplicity
- **Stateless** - Query Docker directly, no state file to corrupt
- **Template-based** - Jinja2 templates for config generation
- **Well-tested** - ShellSpec unit tests with mocked dependencies

**Key Components:**

1. **Registry Parser** - YAML parsing with yq for server definitions
2. **Docker Manager** - Image pulling, building, and health checking
3. **Config Generator** - Jinja2 template rendering for multiple clients
4. **Environment Handler** - Centralized `.env` file management

### Running Tests

```bash
# Install ShellSpec
curl -fsSL https://git.io/shellspec | sh -s -- --yes

# Run all unit tests
shellspec spec/unit/

# Run specific test file
shellspec spec/unit/health_command_spec.sh

# With verbose output
shellspec spec/unit/ --format documentation
```

### Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork and Branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Write Tests First** (TDD)
   ```bash
   # Create test file
   touch spec/unit/my_feature_spec.sh

   # Write failing tests
   shellspec spec/unit/my_feature_spec.sh  # Should fail

   # Implement feature
   nano mcp_manager.sh

   # Tests should pass
   shellspec spec/unit/my_feature_spec.sh
   ```

3. **Follow Code Style**
   - Use `shellcheck` for linting
   - Keep functions focused (single responsibility)
   - Add comments for complex logic
   - Use descriptive variable names

4. **Run Quality Checks**
   ```bash
   # Run all tests
   shellspec

   # Check shell script quality
   shellcheck mcp_manager.sh

   # Run pre-commit hooks
   pre-commit run --all-files
   ```

5. **Commit and Push**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push origin feature/my-feature
   ```

6. **Create Pull Request**
   - Describe what changed and why
   - Reference any related issues
   - Ensure CI passes

### CI/CD Pipeline

GitHub Actions automatically runs on every push:

- **ShellCheck** - Lints shell scripts for common issues
- **ShellSpec** - Runs 237 unit tests
- **YAML Validation** - Checks registry syntax
- **Security Scans** - Detects hardcoded secrets

View status: [GitHub Actions](https://github.com/Govinda-Fichtner/mcp-manager/actions)

### Adding New Servers

See [Adding a Custom Server](#adding-a-custom-server) in the Usage Guide.

**Development Process:**
1. Add entry to `mcp_server_registry.yml`
2. Test with `./mcp_manager.sh info <server>`
3. Create unit test in `spec/unit/servers/<server>_spec.sh`
4. Run tests: `shellspec spec/unit/servers/<server>_spec.sh`
5. Document in PR description

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/Govinda-Fichtner/mcp-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Govinda-Fichtner/mcp-manager/discussions)
- **MCP Specification**: https://modelcontextprotocol.io/

---

**Version**: 0.2.0
**Status**: Active Development
