#!/bin/bash
Describe 'terraform-cli-controller MCP Server'
  Include spec/spec_helper.sh
  export REGISTRY_FILE="$PROJECT_DIR/mcp_server_registry.yml"
  Include mcp_manager.sh
  setup() { setup_test_env; }
  cleanup() { cleanup_test_env; }
  BeforeEach 'setup'
  AfterEach 'cleanup'
  Describe 'Registry Configuration'
    It 'parses server fields'
      When call get_server_field "terraform-cli-controller" "name"
      The status should equal 0
    End
  End
  Describe 'List Command'
    It 'includes terraform-cli-controller in server list'
      When call cmd_list
      The output should include "terraform-cli-controller"
    End
  End
End
