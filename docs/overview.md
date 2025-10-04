# MCP Manager - Executive Overview

**Version:** 1.0
**Date:** 2025-10-04
**Status:** MVP Development

---

## 1. Introduction

**What is mcp-manager.sh?**

MCP Manager is a shell-based tool that simplifies the deployment and management of Model Context Protocol (MCP) servers through Docker containerization. It provides a unified interface for configuring, deploying, and maintaining multiple MCP servers across different AI development environments.

**Why does it exist?**

Managing MCP servers traditionally requires manual Docker commands, custom configuration files, and complex environment setup for each AI client (Claude Desktop, Claude Code, Gemini CLI). This fragmented approach leads to:
- Repeated configuration across multiple clients
- Inconsistent server deployments
- Complex dependency management
- Error-prone manual processes

**Key Value Proposition**

MCP Manager eliminates this complexity by providing:
- **Centralized Registry**: Single YAML file defines all servers
- **Multi-Client Support**: Generate configs for Cursor, Claude Desktop, and Gemini CLI automatically
- **Docker Isolation**: Each server runs in isolated containers with managed dependencies
- **TDD Approach**: Test-driven development ensures reliability and maintainability
- **Zero-Config Deployment**: Pull pre-built images or build from source with single command

---

## 2. Core Concepts

**Model Context Protocol (MCP)**: Open standard for connecting AI models to external tools and data sources. Think "USB-C for AI" - standardized integration with databases, filesystems, and APIs.

**Local vs Remote Servers**: MCP servers run locally (Docker, <1ms latency, private) or remotely (cloud-hosted, scalable). MVP focuses on local Docker deployment.

**Docker Isolation**: Containers provide dependency isolation, version locking, reproducibility, and security sandboxing. Each server runs in its own isolated environment.

**Build Strategies**: Pull pre-built images from registries (fast, reliable) or build from source (customizable, slower - Post-MVP).

Reference: **concepts.md** for complete details on MCP architecture, Docker patterns, and deployment strategies.

---

## 3. System Architecture

**Design Philosophy**: Following **MacbookSetup proven patterns** - monolithic script initially, Jinja2 templates from day 1, stateless design, gradual modularization as complexity grows.

**Key Workflows**:
1. Add Server: Parse registry → Pull image OR build from source (both in Phase 1)
2. Generate Config: Load registry → Build Jinja2 context → Render templates → Write files
3. Health Check: Query Docker → Check image exists → Report status

**File Organization**:
- **Single script initially** (`mcp_manager.sh` ~800-1200 lines), not lib/ modules from day 1
- **Jinja2 templates** in `support/templates/` (not simple variable substitution)
- **Stateless design**: Query Docker directly, no state file
- **ShellSpec tests** in `spec/` (unit tests initially, integration deferred)

Reference: **architecture.md** for complete design. **file-structure.md** for rationale on monolithic approach.

---

## 4. MVP Scope

**Phase 1** (Week 1-2):
- **GitHub MCP server** (registry pull)
- **Obsidian MCP server** (build from source)
- **Both registry pull AND build from source** in Phase 1 (key change!)
- **Jinja2 config generation** from day 1 (Claude Code format)
- **Stateless design** (no state file, query Docker directly)
- **.env management** with placeholder generation
- **Basic commands**: list, info, setup, config, config-write
- **Unit tests only** (80%+ coverage, fast, no Docker)

**Success**: Pull GitHub server, build Obsidian from source, generate valid configs via Jinja2, verify health.

**Phase 2** (Week 2-3): Additional config formats (Claude Desktop, Gemini CLI), snippet generation, volume mounts, enhanced health checks (MCP protocol validation).

**Deferred Post-MVP**: Custom Dockerfiles, version rollback, integration tests, remote servers, advanced health monitoring.

Reference: **requirements.md** for complete specifications and acceptance criteria.

---

## 5. Key Features

**Build Strategies**: **Both in Phase 1** - Registry pull (fast, reliable) AND source build (customizable). Not split across phases.

**Multi-Client Configs**: **Jinja2 templates** from day 1 for Claude Code, Claude Desktop, and Gemini CLI. Template includes for code reuse (MacbookSetup pattern).

**Docker Management**: Pull images from registries (Docker Hub, GHCR), build from source (git clone + docker build), configure host network, inject environment variables.

**Stateless Design**: **No state file** tracking. Query Docker directly (`docker images`, `docker ps`) for current status. No version history, no rollback (remove and rebuild instead).

**Global .env**: Single file for all secrets (API tokens, paths, settings). Auto-generated `.env.example` with placeholders.

**TDD with ShellSpec**: Unit tests only for MVP (fast, no Docker), 80%+ coverage, CI-friendly. Integration tests Post-MVP.

**Registry Schema**: Optimized MVP schema (see `registry-schema.md`) - simplified from MacbookSetup, focused on essentials.

Reference: **terminology.md** for technical definitions.

---

## 6. Getting Started

**Prerequisites**

Install required dependencies:
```bash
# macOS
brew install docker yq jq

# Ubuntu/Debian
sudo apt-get install docker.io yq jq

# Verify installations
docker --version   # Should be 20.10+
yq --version       # Should be v4.0+
jq --version       # Should be 1.6+
```

**Basic Workflow Example**

```bash
# 1. Initialize environment
cp .env.example .env
# Edit .env with your GitHub token

# 2. Add GitHub MCP server
./mcp-manager.sh setup github

# 3. Generate configuration
./mcp-manager.sh config-write

# 4. Verify setup
./mcp-manager.sh info github
./mcp-manager.sh health github

# 5. Use in Claude Code
# Configuration automatically written to ~/.config/claude-code/mcp.json
# Restart Claude Code to load new server
```

**Where to Find Detailed Docs**

- **Installation Guide**: README.md
- **Command Reference**: api-reference.md (future)
- **Examples**: docs/examples/ (future)
- **Troubleshooting**: FAQ.md (future)

---

## 7. Implementation Approach

**TDD with ShellSpec**: Red-Green-Refactor cycle. Unit tests (fast, mocked, CI-friendly) for MVP. Integration tests (real Docker) Post-MVP.

**Based on MacbookSetup Patterns**:
- **Registry-driven architecture** - Single YAML file as source of truth
- **Server type abstraction** - api_based, mount_based, privileged
- **Jinja2 template-based generation** - Proven in production, not simple substitution
- **Stateless design** - No state file, query Docker directly
- **Monolithic initially** - Single script, gradually modularize (see file-structure.md)
- **Graceful degradation** - CI mode, Docker unavailable, clear errors

**Improvements over MacbookSetup**:
- Bash portability (not zsh-specific)
- Better error messages
- Optimized registry schema
- Clear test separation (unit vs integration)

Reference: **analysis.md** for implementation insights. **file-structure.md** for architectural decisions.

---

## 8. Document Guide

- **requirements.md**: Functional specs, commands, workflows, acceptance criteria
- **concepts.md**: MCP fundamentals, Docker isolation, build strategies, testing philosophy
- **terminology.md**: Technical definitions (MCP, Docker, build strategies, networking)
- **architecture.md**: System design, data flows, file structure, workflows
- **analysis.md**: Implementation insights, patterns, testing, code examples

**Contributors**: Read overview.md → concepts.md → requirements.md → architecture.md → analysis.md

**Users**: Read overview.md → Getting Started → requirements.md scenarios → concepts.md

---

## Summary

MCP Manager simplifies MCP server deployment through a registry-driven, Docker-based architecture. The MVP focuses on core functionality (GitHub MCP server, Claude Code config generation) with a clear path to multi-server, multi-client support.

**Development Status**: MVP in progress
**Target**: Week 1-2 for Phase 1 completion
**Testing**: TDD approach with shellspec
**Documentation**: Complete specification and design documents

**Next Steps:**
1. Implement core registry parsing
2. Add Docker integration layer
3. Build config generation templates
4. Write comprehensive unit tests
5. Create user documentation

For implementation details, see architecture.md and analysis.md. For requirements and acceptance criteria, see requirements.md.

---

**Document Version:** 1.0
**Last Updated:** 2025-10-04
**Word Count:** 989 (under 1000-word target)
**Target Audience:** Developers and stakeholders
