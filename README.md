# MCP Manager

> Manage Model Context Protocol (MCP) servers with Docker

MCP Manager is a shell-based tool for managing MCP servers through Docker containerization. It supports both pulling pre-built images from registries and building custom servers from source repositories.

## Features

- ✅ **Registry Pull** - Pull pre-built MCP server images from Docker registries
- ✅ **Build from Source** - Clone and build MCP servers from Git repositories
- ✅ **Multi-Platform** - Automatic platform detection (amd64/arm64)
- ✅ **Configuration Generation** - Generate configs for Claude Code, Claude Desktop, Gemini CLI (coming soon)
- ✅ **Environment Management** - Centralized `.env` file for secrets
- ✅ **Health Checking** - Verify server readiness
- ✅ **TDD Approach** - ShellSpec unit tests for reliability

## Quick Start

### Prerequisites

- **Docker** (20.10+) - Container runtime
- **yq** (v4+) - YAML processor
- **jq** (1.6+) - JSON processor
- **git** - For building from source
- **jinja2-cli** - Template rendering (for config generation)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/mcp-manager.git
cd mcp-manager

# Make script executable
chmod +x mcp_manager.sh

# Check dependencies
./mcp_manager.sh version
```

### Basic Usage

```bash
# List available MCP servers
./mcp_manager.sh list

# Setup GitHub server (registry pull)
./mcp_manager.sh setup github

# Setup Obsidian server (build from source)
./mcp_manager.sh setup obsidian

# Check server information
./mcp_manager.sh info github

# Verify server health
./mcp_manager.sh health github

# Generate configuration (coming soon)
./mcp_manager.sh config github --format claude-code
```

## Configuration

### Registry File

The `mcp_server_registry.yml` file defines available MCP servers. Each server specifies:

- **Source type** - `registry` (pull) or `repository` (build)
- **Docker image** - For registry pulls
- **Git repository** - For source builds
- **Environment variables** - Required secrets/config
- **Volume mounts** - For file system access

See `docs/registry-schema.md` for the complete schema reference.

### Environment Variables

Create a `.env` file from the template:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```bash
# GitHub MCP Server
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here

# Obsidian MCP Server
OBSIDIAN_VAULT_PATH=/path/to/your/vault
```

## Commands

### `list`
List all available MCP servers in the registry.

```bash
./mcp_manager.sh list
```

### `setup <server>`
Setup an MCP server by pulling from registry or building from source.

```bash
# Pull from registry
./mcp_manager.sh setup github

# Build from source
./mcp_manager.sh setup obsidian
```

### `info <server>`
Show detailed information about a server.

```bash
./mcp_manager.sh info github
```

### `health <server>`
Check if a server is ready (Docker image present, daemon accessible).

```bash
./mcp_manager.sh health github
```

### `config <server>` *(Coming Soon)*
Generate MCP client configuration.

```bash
./mcp_manager.sh config github --format claude-code
```

### `version`
Show MCP Manager version and dependency status.

```bash
./mcp_manager.sh version
```

## Architecture

MCP Manager follows the **MacbookSetup proven pattern**:

- **Monolithic Script** - Single `mcp_manager.sh` file initially (800+ lines)
- **Jinja2 Templates** - Powerful config generation from day 1
- **Stateless Design** - Query Docker directly, no state file corruption
- **Gradual Modularization** - Extract to `lib/` only when complexity justifies

See `docs/architecture.md` for detailed system design.

## Project Structure

```
mcp-manager/
├── mcp_manager.sh              # Main script
├── mcp_server_registry.yml     # Server definitions
├── .env                        # Environment variables (gitignored)
├── .env.example                # Environment template
├── support/                    # Supporting files
│   ├── docker/                 # Custom Dockerfiles
│   └── templates/              # Jinja2 config templates
├── spec/                       # ShellSpec tests
│   ├── unit/                   # Fast unit tests
│   ├── integration/            # Docker-based tests
│   └── fixtures/               # Test data
└── docs/                       # Documentation
    ├── overview.md             # Executive summary
    ├── requirements.md         # MVP requirements
    ├── architecture.md         # System design
    ├── concepts.md             # Core concepts
    ├── terminology.md          # Glossary
    ├── registry-schema.md      # Registry file schema
    ├── file-structure.md       # Structure rationale
    └── analysis.md             # MacbookSetup analysis
```

## Development

### Running Tests

```bash
# Install ShellSpec (if not already installed)
curl -fsSL https://git.io/shellspec | sh

# Run unit tests
shellspec spec/unit/

# Run all tests
shellspec
```

### Adding a New MCP Server

1. **Update Registry** (`mcp_server_registry.yml`):

```yaml
servers:
  my-server:
    name: "My Custom Server"
    description: "Description of what it does"
    category: "custom"

    source:
      type: "registry"  # or "repository"
      image: "org/my-server"
      tag: "latest"
      registry: "ghcr.io"

    environment_variables:
      - name: "MY_API_KEY"
        description: "API key for my service"
        required: true
```

2. **Add Environment Variables** (`.env`):

```bash
MY_API_KEY=your_key_here
```

3. **Test**:

```bash
./mcp_manager.sh info my-server
./mcp_manager.sh setup my-server
./mcp_manager.sh health my-server
```

## Documentation

- **[Overview](docs/overview.md)** - High-level summary (< 1000 words)
- **[Requirements](docs/requirements.md)** - MVP functional requirements
- **[Architecture](docs/architecture.md)** - System design and workflows
- **[Concepts](docs/concepts.md)** - MCP fundamentals and design philosophy
- **[Terminology](docs/terminology.md)** - Glossary of key terms
- **[Registry Schema](docs/registry-schema.md)** - Registry file reference
- **[File Structure](docs/file-structure.md)** - Directory organization rationale
- **[Analysis](docs/analysis.md)** - MacbookSetup implementation study

## Roadmap

### Phase 1 - MVP ✅ (Current)
- [x] Dependency checking
- [x] Registry parsing
- [x] Platform detection
- [x] List command
- [x] Info command
- [x] Health command
- [x] Setup command (registry pull)
- [x] Setup command (build from source)
- [ ] Config generation (Jinja2 templates)
- [ ] Unit tests (80%+ coverage)

### Phase 2 - Expansion
- [ ] Claude Desktop config format
- [ ] Gemini CLI config format
- [ ] Config snippet vs full file
- [ ] Integration tests
- [ ] Volume mount support
- [ ] Advanced health checks (MCP protocol)
- [ ] Remove command
- [ ] Shell completions

### Phase 3 - Polish
- [ ] Credential encryption
- [ ] Multi-server orchestration
- [ ] Auto-update
- [ ] Plugin system

## Troubleshooting

### "Missing dependencies"
Install the required tools (see Prerequisites section).

### "Invalid YAML syntax"
Ensure you're using yq v4+ (Go version), not the old Python version:
```bash
yq --version  # Should show v4.x.x
```

### "Failed to pull image"
- Check Docker daemon is running: `docker info`
- Verify registry URL in `mcp_server_registry.yml`
- Check network connectivity

### "Failed to clone repository"
- Verify Git is installed: `git --version`
- Check repository URL is accessible
- Ensure network connectivity

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [MacbookSetup mcp_manager.sh](https://github.com/Govinda-Fichtner/MacbookSetup)
- Built for the [Model Context Protocol](https://modelcontextprotocol.io/)
- Test framework: [ShellSpec](https://shellspec.info/)

## Support

- **Issues**: https://github.com/yourusername/mcp-manager/issues
- **Discussions**: https://github.com/yourusername/mcp-manager/discussions
- **MCP Specification**: https://modelcontextprotocol.io/

---

**Version**: 0.1.0
**Status**: MVP Phase 1 (Active Development)
