#!/bin/bash
# Unit tests for Memory Service MCP server

Describe 'Memory Service MCP Server'
  Include spec/spec_helper.sh
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh

  setup() { setup_test_env; }
  cleanup() { cleanup_test_env; }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  Describe 'Registry Configuration'
    It 'parses server name'
      When call get_server_field "memory-service" "name"
      The output should equal "Memory Service MCP Server"
    End
    It 'parses server type'
      When call get_server_field "memory-service" "server_type"
      The output should equal "mount_based"
    End
    It 'parses description'
      When call get_server_field "memory-service" "description"
      The output should equal "Persistent memory storage and retrieval using ChromaDB for AI applications"
    End
    It 'parses environment variables'
      When call get_server_field "memory-service" "environment_variables"
      The output should include "MCP_MEMORY_CHROMA_PATH"
      The output should include "MCP_MEMORY_BACKUPS_PATH"
    End
    It 'parses volumes'
      When call get_server_field "memory-service" "volumes"
      The output should include "MCP_MEMORY_CHROMA_PATH:/app/chroma_db"
      The output should include "MCP_MEMORY_BACKUPS_PATH:/app/backups"
    End
  End

  Describe 'List Command'
    It 'includes memory-service in server list'
      When call cmd_list
      The output should include "memory-service"
      The output should include "[memory]"
    End
  End
End
