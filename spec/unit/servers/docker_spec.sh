#!/bin/bash
Describe 'docker MCP Server'
  Include spec/spec_helper.sh
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh
  setup() { setup_test_env; }
  cleanup() { cleanup_test_env; }
  BeforeEach 'setup'
  AfterEach 'cleanup'
  Describe 'Registry Configuration'
    It 'parses server name'
      When call get_server_field "docker" "name"
      The output should equal "Docker MCP Server"
    End
  End
  Describe 'List Command'
    It 'includes docker in server list'
      When call cmd_list
      The output should include "docker"
    End
  End
End
