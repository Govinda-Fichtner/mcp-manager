#!/bin/bash
Describe 'recraft MCP Server'
  Include spec/spec_helper.sh
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh
  setup() { setup_test_env; }
  cleanup() { cleanup_test_env; }
  BeforeEach 'setup'
  AfterEach 'cleanup'
  Describe 'Registry Configuration'
    It 'parses server fields'
      When call get_server_field "recraft" "name"
      The status should equal 0
    End
  End
  Describe 'List Command'
    It 'includes recraft in server list'
      When call cmd_list
      The output should include "recraft"
    End
  End
End
