# MCP Server Test Results

**Test Date:** 2025-10-05
**Environment:** mcp-manager project
**Configuration File:** `.env` with `ALLOWED_DIRECTORIES` variable

## Summary

Out of 3 configured MCP servers, **1 is operational** and **2 are failing**.

---

## Test Results

### 1. GitHub MCP Server ✅ **CONNECTED**

**Status:** Fully operational
**Command:** `docker run --rm -i --network host --env-file .env ghcr.io/github/github-mcp-server:latest`
**Result:** ✓ Connected successfully

**Configuration:**
- Environment Variable: `GITHUB_PERSONAL_ACCESS_TOKEN`
- Value configured in `.env` file
- Docker image: `ghcr.io/github/github-mcp-server:latest`

**Available Resources:** Empty list (no resources returned)

**Notes:**
- Successfully authenticates with GitHub
- Container starts and responds properly
- Network host mode works correctly

---

### 2. Filesystem MCP Server ❌ **NOT CONFIGURED**

**Status:** Not available
**Error:** Server "filesystem" not found
**Available Servers:** github, obsidian

**Configuration Status:**
- Environment Variable: `ALLOWED_DIRECTORIES=/home/vagrant/`
- Previously named: `FILESYSTEM_ALLOWED_DIRS` (renamed as requested)

**Issue:**
- The filesystem MCP server is not configured in Claude's MCP server list
- Only `github` and `obsidian` servers are recognized by the MCP tool system
- The environment variable change did not enable the filesystem server

**Next Steps:**
- Verify that filesystem MCP server needs to be added to Claude configuration
- Check if additional setup beyond environment variables is required
- May need to run `claude mcp add filesystem <command>` to register the server

---

### 3. Obsidian MCP Server ❌ **FAILED TO CONNECT**

**Status:** Container running but not accepting connections
**Command:** `docker run --rm -i --network host --env-file .env local/obsidian-mcp-server:latest`
**Result:** ✗ Failed to connect

**Configuration:**
- Environment Variables:
  - `OBSIDIAN_API_KEY=99a8baff196ea69f49fd68af7e1267c64e978fd680be1191267a9bbd8ffc2578`
  - `OBSIDIAN_BASE_URL=https://192.169.178.22:27124`
  - `OBSIDIAN_VERIFY_SSL=false`
  - `OBSIDIAN_ENABLE_CACHE=true`

**Docker Status:**
- Multiple containers running (3 detected)
- Environment variables correctly loaded in container
- Container IDs: 4c05e67ca149, 4f126089d8d7, 0996b1f2479d

**Connection Test:**
```bash
curl -k -H "Authorization: Bearer <API_KEY>" "https://192.169.178.22:27124/vault/"
```
**Result:** `Failed to connect to 192.169.178.22 port 27124 after 0 ms: Could not connect to server`

**Available Resources:** Empty list (no resources returned)

**Issues:**
1. Network connectivity failure to Obsidian API endpoint
2. IP address `192.169.178.22` may not be reachable from current environment
3. Port 27124 not accessible
4. Possible causes:
   - Obsidian Local REST API plugin not running
   - Incorrect IP address (should be local network IP)
   - Firewall blocking the connection
   - Plugin not started in Obsidian application

**Recommendations:**
1. Verify Obsidian is running with Local REST API plugin enabled
2. Confirm the correct IP address and port from Obsidian settings
3. Test network connectivity: `ping 192.169.178.22`
4. Check if the IP should be `localhost` or `127.0.0.1` for local testing
5. Verify port 27124 is open and listening

---

## Environment Variable Changes

**Before:**
- `FILESYSTEM_ALLOWED_DIRS=/home/vagrant/`

**After:**
- `ALLOWED_DIRECTORIES=/home/vagrant/`

The environment variable was successfully renamed as requested.

---

## Overall Assessment

| Server | Status | Connectivity | Resources |
|--------|--------|--------------|-----------|
| GitHub | ✅ Pass | Connected | 0 resources |
| Filesystem | ❌ Fail | Not configured | N/A |
| Obsidian | ❌ Fail | Connection refused | 0 resources |

**Success Rate:** 33% (1 out of 3)

---

## Action Items

1. **Filesystem MCP Server:**
   - Add server to Claude MCP configuration
   - Verify required command/executable path
   - Test with `claude mcp add filesystem <command>`

2. **Obsidian MCP Server:**
   - Fix network connectivity to `192.169.178.22:27124`
   - Verify Obsidian Local REST API plugin is running
   - Consider using localhost/127.0.0.1 if testing locally
   - Check firewall and network settings

3. **GitHub MCP Server:**
   - No action required - working correctly
   - Consider testing with actual GitHub operations to verify full functionality
