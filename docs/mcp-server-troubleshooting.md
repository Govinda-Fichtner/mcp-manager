# MCP Server Troubleshooting Guide

**Purpose:** Document troubleshooting approaches and commands for developing and debugging MCP server support in `mcp_manager.sh`.

**Last Updated:** 2025-10-05

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Server-Specific Issues](#server-specific-issues)
3. [MCP Protocol Testing](#mcp-protocol-testing)
4. [Common Problems](#common-problems)
5. [Development Workflow](#development-workflow)

---

## Quick Diagnostics

### 1. Check if Server Image Exists

```bash
# List all MCP-related images
docker images | grep mcp

# Check specific server image
docker images | grep obsidian-mcp-server
docker images | grep github-mcp-server
docker images | grep mcp-filesystem
```

### 2. Test API Endpoint Availability (for servers requiring external APIs)

```bash
# Test Obsidian Local REST API
curl -k https://192.169.178.129:27124/

# Expected response: {"status": "OK", "manifest": {...}}
```

### 3. Quick Health Check

```bash
# Test specific server
./mcp_manager.sh health <server-name>

# Test all servers
./mcp_manager.sh health
```

---

## Server-Specific Issues

### Obsidian MCP Server

**Common Issues:**

1. **Timeout during health check (before API endpoint fix)**
   - **Symptom:** Health check hangs for 20+ seconds
   - **Cause:** Obsidian Local REST API not reachable
   - **Diagnosis:**
     ```bash
     # Check if API is reachable
     curl -k $OBSIDIAN_BASE_URL

     # Expected: {"status": "OK", ...}
     # If fails: Obsidian not running or wrong URL
     ```
   - **Fix:** Update `OBSIDIAN_BASE_URL` in `.env` file to correct endpoint

2. **Resources not supported**
   - **Symptom:** `⚠ Resources not supported`
   - **Cause:** Obsidian MCP server doesn't implement `resources/list` method
   - **Diagnosis:** This is expected behavior (see MCP Protocol Testing below)
   - **Fix:** None needed - this is normal

**Obsidian-Specific Test Commands:**

```bash
# Test container can start
docker run --rm --env-file .env local/obsidian-mcp-server:latest echo "test"

# Test MCP server responds to initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  timeout 5 docker run -i --env-file .env local/obsidian-mcp-server:latest 2>&1 | head -5

# Full protocol test (initialize + initialized + queries)
timeout 10 docker run -i --env-file .env local/obsidian-mcp-server:latest 2>&1 <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
EOF
```

### GitHub MCP Server

**Common Issues:**

1. **Authentication errors**
   - **Symptom:** Server initializes but tools fail
   - **Diagnosis:**
     ```bash
     # Check if GITHUB_TOKEN is set
     grep GITHUB_TOKEN .env

     # Test token validity
     curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user
     ```

**GitHub-Specific Test Commands:**

```bash
# Test with environment
docker run --rm --env-file .env ghcr.io/github/github-mcp-server:latest

# Full protocol test
timeout 5 docker run -i --env-file .env ghcr.io/github/github-mcp-server:latest <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
EOF
```

### Filesystem MCP Server

**Common Issues:**

1. **Image not built**
   - **Symptom:** `✗ Docker image not found: mcp-filesystem:latest`
   - **Fix:**
     ```bash
     ./mcp_manager.sh setup filesystem
     ```

**Filesystem-Specific Test Commands:**

```bash
# Rebuild if needed
./mcp_manager.sh setup filesystem

# Test built image
docker run --rm mcp-filesystem:latest --version

# Full protocol test
timeout 5 docker run -i mcp-filesystem:latest <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
EOF
```

---

## MCP Protocol Testing

### Understanding MCP stdio Communication

**Key Concepts:**

1. **MCP servers run in continuous mode** - they don't terminate after responding
2. **Responses may arrive out of order** - id:2 might come before id:1
3. **Timeout is normal** - use timeout to collect responses, not indicate failure
4. **Close stdin to signal done** - but server will still wait for more input

### Required Message Sequence

```json
// 1. Initialize (id: 1)
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mcp-manager","version":"1.0.0"}}}

// 2. Initialized notification (no id - this is critical!)
{"jsonrpc":"2.0","method":"initialized"}

// 3. Resources query (id: 2)
{"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}

// 4. Tools query (id: 3)
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
```

### Testing Individual MCP Methods

**1. Test Initialize Only:**

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  timeout 3 docker run -i --env-file .env <image-name> 2>&1
```

**Expected Response:**
```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{...},"serverInfo":{...}}}
```

**2. Test Resources List:**

```bash
timeout 5 docker run -i --env-file .env <image-name> <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}
EOF
```

**Possible Responses:**
```json
// Success
{"jsonrpc":"2.0","id":2,"result":{"resources":[...]}}

// Not supported (expected for some servers)
{"jsonrpc":"2.0","id":2,"error":{"code":-32601,"message":"Method not found"}}
```

**3. Test Tools List:**

```bash
timeout 5 docker run -i --env-file .env <image-name> <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
EOF
```

**Expected Response:**
```json
{"jsonrpc":"2.0","id":3,"result":{"tools":[{"name":"...", "description":"...", "inputSchema":{...}}]}}
```

### Parsing MCP Responses

**Save and analyze output:**

```bash
# Save full output
timeout 5 docker run -i --env-file .env <image-name> 2>&1 <<'EOF' > /tmp/mcp_output.txt
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
EOF

# Extract specific responses
grep '"id":1' /tmp/mcp_output.txt  # Initialize response
grep '"id":2' /tmp/mcp_output.txt  # Resources response
grep '"id":3' /tmp/mcp_output.txt  # Tools response

# Count tools (requires jq)
grep '"id":3' /tmp/mcp_output.txt | jq -r '.result.tools | length'

# Pretty print response
grep '"id":1' /tmp/mcp_output.txt | jq '.'
```

---

## Common Problems

### 1. "Connection timeout"

**Symptom:**
```
⚠ Connection timeout after 20s
```

**Diagnosis Steps:**

1. **Check if server requires external API:**
   ```bash
   # Look for environment variables with URL/endpoint
   grep -E "URL|ENDPOINT|HOST" mcp_server_registry.yml

   # Test external endpoint
   curl -k $API_ENDPOINT_URL
   ```

2. **Test if server responds at all:**
   ```bash
   # Send just initialize and see if we get response
   echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
     timeout 5 docker run -i --env-file .env <image> 2>&1
   ```

3. **Check container logs:**
   ```bash
   # Run in background and check logs
   docker run -d --name mcp-test --env-file .env <image>
   sleep 2
   docker logs mcp-test
   docker stop mcp-test && docker rm mcp-test
   ```

**Common Causes:**
- External API not accessible (Obsidian, GitHub API down, etc.)
- Missing required environment variables
- Network issues (firewall, DNS)
- Server stuck in initialization loop

### 2. "No response from MCP server"

**Symptom:**
```
✗ No response from MCP server (timeout: 5s)
```

**Diagnosis:**

```bash
# Test container starts at all
docker run --rm --env-file .env <image> echo "test"

# Check if there's any output (even errors)
timeout 3 docker run -i --env-file .env <image> 2>&1 <<< '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

**Common Causes:**
- Container fails to start
- Missing dependencies in .env file
- Image corruption (try rebuilding)
- Invalid JSON-RPC request format

### 3. "Resources not supported"

**Symptom:**
```
⚠ Resources not supported
```

**This is usually expected!** Many MCP servers don't implement resources/list. Check the response:

```bash
# Check if it's an error response or no response
grep '"id":2' /tmp/mcp_output.txt

# {"jsonrpc":"2.0","id":2,"error":{"code":-32601,"message":"Method not found"}}
# This is expected - server doesn't support resources
```

### 4. "MCP initialization unclear"

**Symptom:**
```
⚠ MCP initialization unclear
```

**Diagnosis:**

```bash
# Check what initialize response looks like
grep '"id":1' /tmp/mcp_output.txt | jq '.'

# Should contain:
# - "result" field
# - "protocolVersion" field
# - "serverInfo" field
```

**Common Causes:**
- Server returned error instead of success
- Invalid protocol version
- Malformed response

---

## Development Workflow

### Adding Support for a New MCP Server

**Step 1: Add to Registry**

```yaml
# mcp_server_registry.yml
servers:
  new-server:
    name: "New MCP Server"
    description: "Description of what it does"
    category: "productivity"

    source:
      type: "registry"  # or "repository" or "dockerfile"
      registry: "ghcr.io"
      image_name: "org/new-mcp-server"
      tag: "latest"

    environment_variables:
      - name: "API_KEY"
        description: "API key for authentication"
        required: true

    startup_timeout: 5  # Adjust based on server startup time
```

**Step 2: Test Container Manually**

```bash
# Pull/build image
./mcp_manager.sh setup new-server

# Test container starts
docker run --rm --env-file .env <image-name> --help

# Test basic MCP protocol
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | \
  timeout 5 docker run -i --env-file .env <image-name> 2>&1
```

**Step 3: Test Full Protocol Sequence**

```bash
# Use the full test sequence
timeout 10 docker run -i --env-file .env <image-name> 2>&1 <<'EOF' | tee /tmp/new_server_output.txt
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","method":"initialized"}
{"jsonrpc":"2.0","id":2,"method":"resources/list","params":{}}
{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}
EOF

# Analyze responses
grep '"id":1' /tmp/new_server_output.txt | jq '.result.serverInfo'
grep '"id":2' /tmp/new_server_output.txt | jq '.result.resources | length' 2>/dev/null || echo "Resources not supported"
grep '"id":3' /tmp/new_server_output.txt | jq '.result.tools | length'
```

**Step 4: Test with Health Command**

```bash
./mcp_manager.sh health new-server
```

**Step 5: Adjust Timeout if Needed**

If server consistently times out but works:
1. Check if external API is required (network latency)
2. Increase `startup_timeout` in registry
3. Document why longer timeout is needed

**Step 6: Document Troubleshooting**

Add server-specific section to this document with:
- Common issues
- Required environment variables
- External dependencies
- Example test commands

### Debugging Health Check Issues

**Enable verbose output:**

```bash
# Add set -x to see what's happening
bash -x ./mcp_manager.sh health <server-name>
```

**Test the test_mcp_complete function directly:**

```bash
# Source the script
source mcp_manager.sh

# Run function with debugging
set -x
test_mcp_complete "server-name" "image:tag"
set +x
```

**Check intermediate variables:**

```bash
# Add echo statements to test_mcp_complete function
# Before line 716 in mcp_manager.sh:
echo "DEBUG: mcp_output length: ${#mcp_output}"
echo "DEBUG: timeout_exit_code: $timeout_exit_code"
echo "DEBUG: first 200 chars: ${mcp_output:0:200}"
```

---

## Reference: MCP Protocol Specification

**Official Docs:** https://mcpcat.io/guides/understanding-json-rpc-protocol-mcp/

**Key Points:**
1. Initialize → Server responds → Initialized notification → Queries
2. Servers stay alive in stdio mode (don't terminate)
3. Responses can be asynchronous (out of order)
4. Errors are valid JSON-RPC responses

**JSON-RPC 2.0 Error Codes:**
- `-32700`: Parse error
- `-32600`: Invalid Request
- `-32601`: Method not found (expected for unsupported methods)
- `-32602`: Invalid params
- `-32603`: Internal error

---

## Appendix: Useful Commands

### Container Inspection

```bash
# List running containers
docker ps | grep mcp

# Inspect container
docker inspect <container-id>

# View logs
docker logs <container-id>

# Execute commands in running container
docker exec -it <container-id> /bin/sh
```

### Environment Debugging

```bash
# Check what env vars are set
grep -v "^#" .env | grep -v "^$"

# Test specific env var in container
docker run --rm --env-file .env <image> env | grep API_KEY
```

### Image Management

```bash
# Remove old images
docker rmi <image-name>

# Clean up all MCP images
docker images | grep mcp | awk '{print $3}' | xargs docker rmi -f

# Rebuild from scratch
./mcp_manager.sh setup <server-name> --rebuild
```
