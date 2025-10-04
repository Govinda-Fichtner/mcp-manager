# MCP Manager Terminology Glossary

This document provides definitions for key terms used throughout the MCP Manager project, organized alphabetically for easy reference.

---

## A

### amd64
A 64-bit x86 processor architecture, also known as x86-64. The most common architecture for desktop and server computers. When building Docker images, this platform target is typically used for Intel and AMD processors.

**Example:** `docker build --platform linux/amd64`

---

## B

### Bridge Network
A Docker networking mode where containers are connected to a private internal network on the host. Containers can communicate with each other through this network and reach external networks through NAT. This is the default Docker network mode.

**Contrast with:** Host Network

### Build Strategy
The method used to obtain an MCP server implementation. MCP Manager supports two primary strategies:

1. **Registry Strategy**: Pull pre-built container images from a registry
2. **Source Strategy**: Build container images from source code (Dockerfile)

**Example:**
```yaml
servers:
  example-server:
    build_strategy: registry  # or 'source'
```

---

## C

### Client (MCP Client)
An application that connects to MCP servers to access their capabilities. Clients initiate connections, send requests, and consume tools, resources, and prompts exposed by servers. Examples include Claude Desktop, IDEs, and custom applications.

**Relationship:** Client → Transport → Server

### Commands
CLI operations provided by MCP Manager for interacting with MCP servers:

- **info**: Display server metadata and configuration details
- **health**: Check if a server is running and responsive
- **build**: Build a container image from source
- **pull**: Download a pre-built container image from a registry
- **config**: Generate Claude Desktop configuration (snippet or full)

### Complete Config
A full Claude Desktop configuration file including all registered MCP servers. Generated with the `config` command without the `--snippet` flag. Overwrites the entire `mcpServers` section.

**Usage:** `mcp-manager config --full > ~/.config/claude/config.json`

**Contrast with:** Config Snippet

### Config Snippet
A partial Claude Desktop configuration containing only a single MCP server definition. Can be manually merged into an existing configuration file. Generated with the `config --snippet` command.

**Usage:** `mcp-manager config my-server --snippet`

**Contrast with:** Complete Config

### Container
A lightweight, standalone, executable package that includes everything needed to run a piece of software: code, runtime, system tools, libraries, and settings. Containers isolate applications from each other and from the host system.

**In MCP Manager:** Each MCP server runs in its own container for isolation and reproducibility.

---

## D

### Dockerfile
A text file containing instructions for building a Docker image. Specifies the base image, dependencies, files to copy, environment variables, and commands to run.

**Example:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "server.py"]
```

### Docker Hub
The default public container registry operated by Docker. Hosts millions of container images that can be pulled and used. Images are referenced as `username/image:tag` or `image:tag` for official images.

**Example:** `docker.io/library/python:3.11-slim`

---

## G

### GHCR (GitHub Container Registry)
A container registry hosted by GitHub for storing and distributing container images. Images are namespaced by GitHub username or organization.

**Example:** `ghcr.io/modelcontextprotocol/servers/sqlite:latest`

---

## H

### Health Check
A mechanism to verify that an MCP server is running and responsive. MCP Manager's `health` command attempts to connect to a server and validate its status.

**Usage:** `mcp-manager health my-server`

**Returns:** Running status, connection details, and any error messages

### Host Network
A Docker networking mode where containers share the host's network stack directly. Containers have access to all network interfaces on the host and use the host's IP address.

**Use case:** Required for MCP servers using stdio transport to communicate with Claude Desktop

**Example:** `docker run --network host`

---

## I

### Image
A read-only template used to create Docker containers. Contains the application code, runtime, libraries, and dependencies. Images are built from Dockerfiles or pulled from registries.

**Relationship:** Image → Container (an image becomes a container when executed)

---

## M

### MCP (Model Context Protocol)
An open protocol that standardizes how applications provide context to Large Language Models (LLMs). MCP enables LLMs to securely access tools, data sources, and services through a uniform interface.

**Key benefit:** Separates AI capabilities from data access, allowing secure and modular integrations

### MCP Server
A program that implements the Model Context Protocol server specification. Exposes tools, resources, and prompts that clients can discover and use. Servers handle requests from clients over a transport layer.

**Examples:** Database servers, filesystem servers, API integration servers

### mcp_server_registry.yml
The central registry file that defines all available MCP servers in MCP Manager. Contains metadata, configuration, and deployment instructions for each server.

**Location:** Typically in the project root or config directory

**Structure:**
```yaml
servers:
  server-name:
    name: Display Name
    description: What this server does
    transport: stdio
    build_strategy: registry
    # ... additional configuration
```

---

## P

### Platform
The combination of operating system and processor architecture for which a container image is built. Docker supports multi-platform images.

**Common platforms:**
- `linux/amd64` - Linux on 64-bit x86
- `linux/arm64` - Linux on 64-bit ARM (Apple Silicon, Raspberry Pi)

**Example:** `docker build --platform linux/arm64`

### Prompt (MCP Primitive)
A pre-defined template or workflow that clients can use to interact with LLMs. One of the three core primitives in MCP, alongside tools and resources. Prompts can include variables and generate structured interactions.

**Example:** A prompt template for analyzing code quality with specific parameters

---

## R

### Registry
A storage and distribution system for Docker images. Registries host images that can be pushed (uploaded) and pulled (downloaded). Can be public or private.

**Major registries:**
- Docker Hub (`docker.io`)
- GitHub Container Registry (`ghcr.io`)
- Google Container Registry (`gcr.io`)
- Amazon ECR (`*.dkr.ecr.*.amazonaws.com`)

### Resource (MCP Primitive)
Data or content that an MCP server exposes to clients. One of the three core primitives in MCP. Resources can be files, database records, API responses, or any other data that provides context to LLMs.

**Example:** A database server exposing table schemas as resources

---

## S

### Server Definition
A complete specification of an MCP server in the registry file. Includes all metadata, configuration, and deployment details needed to run the server.

**Required fields:**
- `name`: Display name
- `description`: Purpose and capabilities
- `transport`: Communication protocol
- `build_strategy`: How to obtain the server

### Server State
The current operational status of an MCP server container. States include:
- **Running**: Container is active and accepting connections
- **Stopped**: Container exists but is not running
- **Not Found**: Container does not exist
- **Error**: Container encountered a problem

### SSE (Server-Sent Events)
A transport protocol for MCP where the server sends events to the client over HTTP. The client connects to an HTTP endpoint and receives a stream of events. Useful for web-based integrations and long-lived connections.

**Characteristics:** Unidirectional (server to client), HTTP-based, text format

### stdio (Standard Input/Output)
A transport protocol for MCP where communication occurs through the standard input and output streams. The simplest transport method, commonly used for local integrations where the client launches the server as a subprocess.

**Characteristics:** Bidirectional, process-based, simple to implement

**Example:** Claude Desktop launching an MCP server as a child process

---

## T

### Tool (MCP Primitive)
A function or capability that an MCP server exposes to clients. One of the three core primitives in MCP. Tools allow LLMs to perform actions like querying databases, calling APIs, or manipulating files.

**Example:** A SQL tool that executes database queries

### Transport
The communication layer used between MCP clients and servers. Defines how messages are sent and received. MCP supports multiple transport protocols to accommodate different deployment scenarios.

**Supported transports:**
- **stdio**: Process-based communication through standard streams
- **SSE**: HTTP-based server-sent events
- **WebSocket**: Bidirectional persistent connections

**Configuration example:**
```yaml
transport: stdio
transport_options:
  command: python
  args: ["-m", "server"]
```

---

## V

### Volume Mounting
A Docker feature that maps a directory or file from the host filesystem into a container. Allows containers to access and persist data outside the container filesystem. Essential for MCP servers that need to access local files or maintain persistent state.

**Example:** `docker run -v /host/path:/container/path`

**Use case:** Mounting a database directory so data persists after container restarts

---

## W

### WebSocket
A transport protocol for MCP providing full-duplex bidirectional communication over a single TCP connection. Enables real-time, low-latency interactions between clients and servers. Suitable for web applications and remote server deployments.

**Characteristics:** Bidirectional, connection-oriented, efficient for frequent messages

**Example:** A web-based MCP client connecting to a remote server over WebSocket

---

## Additional Resources

For more information, see:
- [MCP Specification](https://modelcontextprotocol.io/docs)
- [Docker Documentation](https://docs.docker.com)
- [MCP Manager README](../README.md)

---

*Last updated: 2025-10-04*
